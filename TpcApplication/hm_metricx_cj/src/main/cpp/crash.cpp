//
// Created on 2025/4/1.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#include "crash.h"
#include "common.h"
#include "memory/memory_monitor.h"
#include <bundle/native_interface_bundle.h>
#include <filesystem>
#include <fstream>
#include <hilog/log.h>
#include <iostream>
#include <malloc.h>
#include <pthread.h>
#include <signal.h>
#include <sstream>
#include <stdexcept>
#include <stdlib.h>
#include <string.h>
#include <string>
#include <sys/eventfd.h>
#include <syscall.h>
#include <unistd.h>
#include <deque>
#include <ostream>

using namespace kwai::memory_monitor;
typedef struct {
    int sigNum;
    struct sigaction oldact;
} SignalCrashInfo;

struct LogEntry {
    std::chrono::time_point<std::chrono::system_clock> now;
    LogType type;
    LogLevel level;
    unsigned int domain;
    std::string tag;
    std::string msg;
};

static pthread_mutex_t signalHandlerMutex = PTHREAD_MUTEX_INITIALIZER;

static sig_atomic_t inCrash = 0;

int initSuccess = 0;

typedef const char *(*CollectCrashInfo)();

CollectCrashInfo cjCollectCrashInfo;

typedef void (*Callback)(const char *, const char *, CollectCrashInfo, const char *, const char *, const char *,
                         char *);

Callback cjcb;

std::string persistentFilePath;

std::string persistentSystemLogFilePath;
std::string persistentLastNHilogFilePath;

std::string persistentMemMapFilePath;
std::string persistentMemMallocFilePath;
std::string persistentPcParseFilePath;

const char *levelChars = "DIWEF"; // 3->D, 4->I, 5->W, 6->E, 7->F

std::vector<LogEntry> logMessages;
std::deque<LogEntry> hilogMessages;
int64_t LASTN_HILOG_NUMBER = 0;

std::string cjLimits;

static SignalCrashInfo signalCrashInfo[] = {{.sigNum = SIGABRT}, {.sigNum = SIGBUS},   {.sigNum = SIGFPE},
                                            {.sigNum = SIGILL},  {.sigNum = SIGSEGV},  {.sigNum = SIGTRAP},
                                            {.sigNum = SIGSYS},  {.sigNum = SIGSTKFLT}};

int RemoveSignalHandler() {
    int r = SUCCESS;
    size_t i;
    for (i = 0; i < sizeof(signalCrashInfo) / sizeof(signalCrashInfo[0]); i++) {
        if (0 != sigaction(signalCrashInfo[i].sigNum, &(signalCrashInfo[i].oldact), NULL)) {
            r = FAIL;
        }
    }
    return r;
}

static std::string readFile(std::string filePath) {
    if (std::__fs::filesystem::exists(filePath)) {
        std::ifstream file(filePath);
        if (file.is_open()) {
            std::string content((std::istreambuf_iterator<char>(file)), std::istreambuf_iterator<char>());
            return content;
        }
    }
    return "";
}

static std::string getVss(const std::string &s, char delimiter) {
    std::string token;
    std::istringstream tokenStream(s);
    if (std::getline(tokenStream, token, delimiter)) {
        return std::to_string(std::stoi(token) * 4);
    }
    return "";
}

void CrashSystemlogCallback(const LogType type, const LogLevel level, const unsigned int domain, const char *tag,
                        const char *msg) {

    int typeValue = static_cast<int>(type);
    if (typeValue != 3) {
        return;
    }

    // current time
    auto now = std::chrono::system_clock::now();

    LogEntry entry;
    entry.now = now;
    entry.type = type;
    entry.level = level;
    entry.domain = domain;
    entry.tag = tag;
    entry.msg = msg;

    logMessages.push_back(entry);
}

void CrashLastNHilogCallback(const LogType type, const LogLevel level, const unsigned int domain, const char *tag,
                        const char *msg) {
    
    // current time
    auto now = std::chrono::system_clock::now();

    LogEntry entry;
    entry.now = now;
    entry.type = type;
    entry.level = level;
    entry.domain = domain;
    entry.tag = tag;
    entry.msg = msg;
    hilogMessages.push_back(entry);
    if (hilogMessages.size() > LASTN_HILOG_NUMBER) {
        hilogMessages.pop_front();
    }
}

extern "C" {
int8_t writeSystemLog(const char *pFilePath);
int8_t writeLastNHiLog(const char *pFilePath);
}

static void CrashSignalHandler(int sig, siginfo_t *si, void *context) {
    if (initSuccess == 0) {
        signalCrashInfo[sig].oldact.sa_sigaction(sig, si, context);
        return;
    }
    pthread_mutex_lock(&signalHandlerMutex);
    if (inCrash) {
        pthread_mutex_unlock(&signalHandlerMutex);
        signalCrashInfo[sig].oldact.sa_sigaction(sig, si, context);
        return;
    }
    inCrash = 1;
    std::string fds = "";
    if (std::__fs::filesystem::exists("/proc/self/fd")) {
        for (auto &entry : std::__fs::filesystem::directory_iterator("/proc/self/fd")) {
            auto path = entry.path();
            fds += path.string() + ",";
            try {
                fds += std::__fs::filesystem::canonical(path).string() + ",";
            } catch (const std::__fs::filesystem::filesystem_error &e) {
                fds += "unknown,";
            }
        }
    }
    std::string threads = readFile("/proc/self/tids");
    std::string smaps_rollup = readFile("/proc/self/smaps_rollup");
    std::string vss = "Vss:\t\t\t\t" + getVss(readFile("/proc/self/statm"), ' ') + " KB";
    std::string meminfo = smaps_rollup + "\n" + vss;
    cjcb(persistentFilePath.c_str(), cjLimits.c_str(), cjCollectCrashInfo, fds.c_str(), threads.c_str(), meminfo.c_str(),
         OH_NativeBundle_GetCurrentApplicationInfo().bundleName);
    writeSystemLog(persistentSystemLogFilePath.c_str());
    persistentMemoryData(persistentMemMapFilePath.c_str(),persistentMemMallocFilePath.c_str(),
                            persistentPcParseFilePath.c_str());
    writeLastNHiLog(persistentLastNHilogFilePath.c_str());
    RemoveSignalHandler();
    pthread_mutex_unlock(&signalHandlerMutex);
    signalCrashInfo[sig].oldact.sa_sigaction(sig, si, context);
}

int8_t saveMemoryMapToFile(const char *pFilePath){
    if(!std::__fs::filesystem::exists("/proc/self/maps")) {
        return FAIL;
    }
    std::ifstream inputFile("/proc/self/maps");
    std::ofstream outputFile(pFilePath);
    
    if(!inputFile.is_open()) {
        return FAIL;
    }
    
    if(!outputFile.is_open()) {
        return FAIL;
    }
    
    std::string line;
    while(std::getline(inputFile, line)) {
        outputFile << line << std::endl;
    }
    inputFile.close();
    outputFile.close();
    
    return SUCCESS;

}

std::string cParseStackFrame(int64_t *c_array,int64_t size){
    if(c_array==nullptr ||size<=0){
        return nullptr;
    }
    void *dl_cache=nullptr;
    ostringstream oss;
    
    auto &monitor = MemoryMonitor::GetInstance();
    for(int64_t i=0;i<size;++i){
        string frame= monitor.ParseStackFrame(c_array[i],&dl_cache);
        oss<<frame;
    }
    return oss.str();
}

bool saveParsedAddressToFile(const char *pcParsePath){

    const auto &backtrace =MemoryMonitor::GetInstance().unique_backtrace;
    size_t size=backtrace.size();
    if(size ==0){
        OH_LOG_Print(LOG_APP,LOG_WARN,0x00008,"MemoryMonitor","saveParsedAddressToFile - unique_backtarce is empty");
        return false;
    }

    unique_ptr<int64_t[]> c_array(new int64_t[size]);
    copy(backtrace.begin(),backtrace.end(),c_array.get());

    std::string parseResult = cParseStackFrame(c_array.get(),backtrace.size());
    if(parseResult.empty()){
        OH_LOG_Print(LOG_APP,LOG_WARN,0x00008,"MemoryMonitor","saveParsedAddressToFile - Failed to parse stack frame");
        return false;
    }

    ofstream ofs(pcParsePath);
    if(!ofs.is_open()){
        OH_LOG_Print(LOG_APP,LOG_WARN,0x00008,"MemoryMonitor","saveParsedAddressToFile - Failed to open file '%s' for writing",pcParsePath);
        return false;

    }

    ofs<<parseResult;
    ofs.close();
    return true;
}

std::string LogEntryToString(const LogEntry &entry) {
    // dateTime
    std::time_t currentTime = std::chrono::system_clock::to_time_t(entry.now);
    std::tm localTime = *std::localtime(&currentTime);

    // millisecond
    auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(
              entry.now - std::chrono::system_clock::from_time_t(currentTime)).count() % 1000;
    // format time
    char timeBuffer[80];
    std::strftime(timeBuffer, sizeof(timeBuffer), "%m-%d %H:%M:%S", &localTime);
    std::ostringstream timeStream;
    timeStream << timeBuffer << "." << std::setw(3) << std::setfill('0') << ms;
    std::string formattedTime = timeStream.str();

    // format level
    char levelChar = '?';
    if (entry.level >= LOG_DEBUG && entry.level <= LOG_FATAL) {
        levelChar = levelChars[entry.level - LOG_DEBUG];
    }

    // format domain
    std::stringstream domainStream;
    domainStream << std::hex << std::uppercase << entry.domain;
    std::string hexDomain = domainStream.str();
    if (hexDomain.length() > 5) {
        hexDomain = hexDomain.substr(hexDomain.length() - 5);
    } else {
        while (hexDomain.length() < 5) {
            hexDomain = "0" + hexDomain;
        }
    }
    if (entry.type == 0) {
        hexDomain = "A" + hexDomain;
    } else if (entry.type == 3){
        hexDomain = "C" + hexDomain;
    }

    std::string res = formattedTime + "  " + hexDomain + "/" + entry.tag + "  " + levelChar + " " + entry.msg;
    return res;
}

extern "C" {
int8_t InitNativeSignalHandler(const char *pFilePath, const char *limits, CollectCrashInfo collectCrashInfo,
                               const char *pSystemLogFilePath, 
                               const char *pMemMapFilePath, const char *pMemMallocPath,
                               const char *pcParsePath,const char *pLastNHilogFilePath,
                                int64_t lastNHilogNumber, Callback cb) {
    LASTN_HILOG_NUMBER = lastNHilogNumber;
    struct sigaction act;
    memset(&act, 0, sizeof(act));
    sigfillset(&act.sa_mask);
    act.sa_sigaction = CrashSignalHandler;
    act.sa_flags = SA_RESTART | SA_SIGINFO | SA_ONSTACK;

    size_t i;
    for (i = 0; i < sizeof(signalCrashInfo) / sizeof(signalCrashInfo[0]); i++) {
        if (0 != sigaction(signalCrashInfo[i].sigNum, &act, &(signalCrashInfo[i].oldact))) {
            RemoveSignalHandler();
            return FAIL;
        }
    }
    initSuccess = 1;

    persistentFilePath=pFilePath;
    persistentSystemLogFilePath=pSystemLogFilePath;
    persistentMemMapFilePath= pMemMapFilePath;
    persistentMemMallocFilePath=pMemMallocPath;
    persistentPcParseFilePath=pcParsePath;
    persistentLastNHilogFilePath=pLastNHilogFilePath；
    cjLimits=limits;

    cjCollectCrashInfo = collectCrashInfo;
    cjcb = cb;
    return SUCCESS;
}

int8_t registerCrashSystemlogCallback() {
    registerHilogCallback(CrashSystemlogCallback);
    return SUCCESS;
}

int8_t registerCrashLastNHilogCallback() {
    registerHilogCallback(CrashLastNHilogCallback);
    return SUCCESS;
}




int8_t writeSystemLog(const char *pFilePath) {
    std::ofstream file(pFilePath);
    if (!file.is_open()) {
        return FAIL;
    }
    for (const auto &entry : logMessages) {
        std::string entryString = LogEntryToString(entry);
        std::ostringstream logStream;
        logStream << entryString;
        file << logStream.str() << "\n";
    }
    file.close();
    return SUCCESS;
}

int8_t writeLastNHiLog(const char *pFilePath) {
    std::ofstream file(pFilePath);
    if (!file.is_open()) {
        return FAIL;
    }
    for (const auto &entry : hilogMessages) {ningwei
        
        std::string entryString = LogEntryToString(entry);
        std::ostringstream logStream;
        logStream << entryString;
        file << logStream.str() << "\n";
    }
    file.close();
    return SUCCESS;
}

int8_t installNativeMemoryMonitor(){
    if(!MemoryMonitor::GetInstance().Install(nullptr,nullptr)){
        return -1;
    }
    return 0;
}

int8_t persistMemeoryData(const char *mapPath, const char *allocRecordsPath, const char *parsedAddrPath){
    try{
        MemoryMonitor::GetInstance().SaveAllocationRecordsToFile(allocRecordsPath);
        saveMemoryMapToFile(mapPath);
        saveParsedAddressToFile(parsedAddrPath);
        return 0;
    } catch(const exception &e){
        OH_LOG_Print(LOG_APP,LOG_WARN,0x00008,"MemoryMonitor","persistMemeoryData - exception: %s",e.what());
        return -1;
    }
}

void hello(){
    int *ptr= nullptr;
    *ptr =42;
}

}