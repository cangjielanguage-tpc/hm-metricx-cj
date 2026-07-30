const NAV_PARAM: string = '8000'

/**
 * Switch-Result 白屏触发入口页:第一个按钮进入切换结果白屏页(预期上报白屏),
 * 其余为对照页(不应判为白屏)。
 */
@Component
export struct SwitchResultTriggerPage {
  @State pageStack: NavPathStack = new NavPathStack()

  build(): void {
    NavDestination() {
      Column() {
        Text('Switch-result white screen trigger page')
          .fontSize(20)
          .margin({ bottom: 12 })
        Text('The first button keeps the next page white for a while before real content appears.')
          .fontSize(16)
          .margin({ bottom: 8 })
        Text('Other buttons are contrast pages for manual comparison.')
          .fontSize(15)
          .fontColor('#666666')
          .margin({ bottom: 20 })
        Button('Go To Switch-Result White Screen').onClick((): void => {
          this.pageStack.pushPath(new NavPathInfo('SwitchResultBlankPage', NAV_PARAM))
        })
        Button('Go To Switch-Result Half Blank Control').margin({ top: 12 }).onClick((): void => {
          this.pageStack.pushPath(new NavPathInfo('HalfBlankPage', NAV_PARAM))
        })
        Button('Go To Switch-Result Image Control').margin({ top: 12 }).onClick((): void => {
          this.pageStack.pushPath(new NavPathInfo('ImagePage', NAV_PARAM))
        })
        Button('Go To Switch-Result Delayed Image').margin({ top: 12 }).onClick((): void => {
          this.pageStack.pushPath(new NavPathInfo('SlowImagePage', NAV_PARAM))
        })
        Button('Go To Switch-Result Slow Load Control').margin({ top: 12 }).onClick((): void => {
          this.pageStack.pushPath(new NavPathInfo('SlowLoadPage', NAV_PARAM))
        })
        Button('Back To Home').margin({ top: 16 }).onClick((): void => {
          this.pageStack.pop()
        })
      }
      .width('100%')
      .height('100%')
      .padding(24)
      .backgroundColor('#F5F5F5')
    }
    .hideTitleBar(true)
    .onReady((context): void => {
      this.pageStack = context.pathStack
    })
    .onBackPressed((): boolean => {
      this.pageStack.pop()
      return true
    })
  }
}
