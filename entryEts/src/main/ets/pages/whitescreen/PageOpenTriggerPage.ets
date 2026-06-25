const NAV_PARAM: string = '8000'

/**
 * Page-Open 白屏触发入口页:提供进入各类白屏/对照页的按钮。
 * 第一个按钮进入真正的白屏页(预期检测器上报白屏),其余为对照页(不应判为白屏)。
 */
@Component
export struct PageOpenTriggerPage {
  @State pageStack: NavPathStack = new NavPathStack()

  build(): void {
    NavDestination() {
      Column() {
        Text('Page-open white screen trigger page')
          .fontSize(20)
          .margin({ bottom: 12 })
        Text('Expected Positive means the detector should report white screen.')
          .fontSize(16)
          .margin({ bottom: 8 })
        Text('Control pages are for contrast and should not be treated as real white screens.')
          .fontSize(15)
          .fontColor('#666666')
          .margin({ bottom: 20 })
        Button('Go To TTID Timeout White Screen').onClick((): void => {
          this.pageStack.pushPath(new NavPathInfo('BlankPage', NAV_PARAM))
        })
        Button('Go To Half Blank Control Page').margin({ top: 12 }).onClick((): void => {
          this.pageStack.pushPath(new NavPathInfo('HalfBlankPage', NAV_PARAM))
        })
        Button('Go To Image Control Page').margin({ top: 12 }).onClick((): void => {
          this.pageStack.pushPath(new NavPathInfo('ImagePage', NAV_PARAM))
        })
        Button('Go To Delayed Image Page (Experimental)').margin({ top: 12 }).onClick((): void => {
          this.pageStack.pushPath(new NavPathInfo('SlowImagePage', NAV_PARAM))
        })
        Button('Go To Slow Load Control Page').margin({ top: 12 }).onClick((): void => {
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
