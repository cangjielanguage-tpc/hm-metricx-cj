@Entry
@Component
struct Index {
  @State message: string = 'Hello World';

  build() {
    RelativeContainer() {
      Text(this.message)
        .id('HelloWorld')
        .fontSize($r('app.float.page_text_font_size'))
        .fontWeight(FontWeight.Bold)
        .alignRules({
          center: { anchor: '__container__', align: VerticalAlign.Center },
          middle: { anchor: '__container__', align: HorizontalAlign.Center }
        })
        .onClick(() => {
          this.message = 'Welcome';
          //oom();
          throw Error("my error")
          // while (true) {
          // }
        })
    }
    .height('100%')
    .width('100%')
  }
}

function oom() {
  let hugeArray: number[] = new Array(Number.MAX_SAFE_INTEGER);
}