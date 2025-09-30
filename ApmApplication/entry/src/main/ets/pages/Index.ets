@Component
export struct PageOne {
  @Consume('pageInfos') pageInfos: NavPathStack;
  build() {
    NavDestination() {
      Column() {
        Text('PageOne')
      }
    }.onReady(context => {
      this.pageInfos = context.pathStack
    }).onBackPressed( () => {
      this.pageInfos.pop();
      return true;
    })
  }
}

@Component
export struct PageTwo {
  @Consume('pageInfos') pageInfos: NavPathStack;
  build() {
    NavDestination() {
      Column() {
        Text('PageTwo')
      }
    }.onReady(context => {
      this.pageInfos = context.pathStack
    }).onBackPressed( () => {
      this.pageInfos.pop();
      return true;
    })
  }
}

@Entry
@Component
struct Index {
  @State message: string = 'Hello World';
  @Provide('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  private arr: number[] = [1, 2, 3]

  @Builder
  PageMap(name: String) {
    if (name == 'pageOne') {
      PageOne();
    } else {
      PageTwo()
    }
  }

  build() {
    RelativeContainer() {
      Column() {
        Button("freeze").onClick(() => {
          freeze()
        })
        Button("arkts crash").onClick(() => {
          crash()
        })

        Button("oom").onClick(() => {
          oom()
        })
        Button("laggy").onClick(() => {
        })

        Navigation(this.pageInfos) {
          TextInput({ placeholder: 'search...' }).height(40).width(90).backgroundColor('#FFFFFF')

          List({ space: 20 }) {
            ForEach(this.arr, (item: number) => {
              ListItem() {
                Text('Page' + item)
                  .width('100%')
                  .height(72)
                  .fontSize(16)
                  .textAlign(TextAlign.Center)
                  .borderRadius(24)
                  .backgroundColor('#FFFFFF')
                  .onClick(() => {
                    this.pageInfos.pushPath({ name: 'pageOne' })
                  })
              }
            }, (item: number) => item.toString())
          }.scrollBar(BarState.Off).width('90%')
        }
        .mode(NavigationMode.Auto)
        .navDestination(this.PageMap)
      }
    }
    .height('100%')
    .width('100%')
  }
}

function freeze() {
  while (true) {

  }
}

function crash() {
  crash()
}

function oom() {
  let hugeArray: number[] = new Array(Number.MAX_SAFE_INTEGER)
}