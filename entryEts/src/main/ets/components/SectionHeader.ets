/**
 * 卡片分区标题。各功能卡片统一调用以保持视觉一致。
 */
@Builder
export function SectionHeader(title: string): void {
  Text(title)
    .fontSize(16)
    .fontWeight(FontWeight.Bold)
    .fontColor('#1A2233')
    .margin({ bottom: 4 })
}
