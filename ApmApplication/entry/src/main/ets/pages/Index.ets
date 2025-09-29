@Entry
@Component
struct Index {
  @State message: string = 'Hello World';

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