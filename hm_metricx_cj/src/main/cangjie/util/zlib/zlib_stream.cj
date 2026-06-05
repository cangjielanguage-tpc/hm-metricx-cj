/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2025. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

/**
 * @file
 *
 * Define CompressInputStream/CompressOutputStream/DevompressInputStream/DecompressOutputStream class
 */
package ohos_app_cangjie_hm_metricx_cj.util.zlib

import std.io.OutputStream

/*
 * Maximum length of the input/output buffer for a single compression/decompression is the max of UInt32
 */
const MAX_BUFFER_LENGTH_IN: Int64 = 0xFFFF_FFFF
const MAX_BUFFER_LENGTH_OUT: Int64 = 0xFFFF_FFFF

/**
 * Implement an output stream for compressing data into other output streams.
 */
public class CompressOutputStream <: OutputStream {
    /* Internal Compressor */
    private var deflater: Deflate

    /* Output stream for writing compressed data */
    private var outputStream: OutputStream

    /* Buffer for storing compressed data */
    private var outBuf: Array<Byte>

    /* Cursor for outBuf */
    private var outBufCursor: Int64

    /* Flag whether writing has started */
    private var writeStarted: Bool

    /* Flag whether the current class is closed */
    private var closed: Bool

    /**
     * Create a output stream for compressing data into outputStream.
     *
     * @parm outputStream Output stream of compressed data to be written
     *
     * @throws ZlibException if bufLen <= 0 or failed to malloc memory for zlib stream,
     * or failed to init encode resource.
     */
    public init(outputStream: OutputStream) {
        outBuf = Array<Byte>(512, repeat: 0)
        outBufCursor = 0
        deflater = Deflate()
        this.outputStream = outputStream
        writeStarted = false
        closed = false
    }

    /**
     * Compresses inBuf data and writes to output stream.
     *
     * @parm inBuf Buffer for storing data to be compressed
     *
     * @throws ZlibException if the CompressOutputStream is closed or failed to encode stream.
     */
    public func write(inBuf: Array<Byte>): Unit {
        if (deflater.isFinished() || closed) {
            throw ZlibException("The CompressOutputStream is closed.")
        }
        if (inBuf.size == 0) {
            return
        }
        writeStarted = true
        var inBufCursor = 0
        var singleInLen = min(inBuf.size, MAX_BUFFER_LENGTH_IN)
        while (singleInLen > 0) {
            deflater.addInputBytes(inBuf.slice(inBufCursor, singleInLen), singleInLen)
            inBufCursor += singleInLen
            while (!deflater.needsInput()) {
                if (outBufCursor == outBuf.size) {
                    flushOutBuf()
                }
                var singleOutLen = min(outBuf.size - outBufCursor, MAX_BUFFER_LENGTH_OUT)
                outBufCursor += deflater.deflate(outBuf.slice(outBufCursor, singleOutLen), NoFlush)
            }
            singleInLen = min(inBuf.size - inBufCursor, MAX_BUFFER_LENGTH_IN)
        }
    }

    /**
     * Flushes compressed data from the internal buffer and writes to the bound output stream.
     * Then refreshes the bound output stream.
     *
     * @throws ZlibException if the CompressOutputStream is closed or failed to encode stream.
     */
    public func flush(): Unit {
        flushOutBuf()
        outputStream.flush()
    }

    /**
     * Closes this stream and release internal compressor resources.
     *
     * @throws ZlibException if the CompressOutputStream is closed, or failed to encode stream,
     * or failed to release compression resources.
     */
    public func close(): Unit {
        if (closed) {
            return
        }
        try {
            if (writeStarted) {
                finishDeflate()
            }
        } finally {
            deflater.deflateEnd()
            closed = true
        }
    }

    private func finishDeflate(): Unit {
        while (!deflater.isFinished()) {
            if (outBufCursor == outBuf.size) {
                flushOutBuf()
            }
            var singleOutLen = min(outBuf.size - outBufCursor, MAX_BUFFER_LENGTH_OUT)
            outBufCursor += deflater.deflate(outBuf.slice(outBufCursor, singleOutLen), Finish)
        }
        flush()
    }

    /**
     * Write outBuf to the bound output stream.
     *
     * @throws ZlibException if the CompressOutputStream is closed or failed to encode stream.
     */
    private func flushOutBuf(): Unit {
        outputStream.write(outBuf.slice(0, outBufCursor))
        outBufCursor = 0
    }
}
