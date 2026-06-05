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
 * Defines common constants/type/function for compression/decompression
 */
package ohos_app_cangjie_hm_metricx_cj.util.zlib

const DEFAULTCOMPRESSION_LEVEL: Int32 = 6
const MAX_WBITS: Int32 = 15

/*
 * Flush Type
 *
 * Z_PARTIAL_FLUSH is not supported currently.
 * Z_SYNC_FLUSH is not supported currently.
 * Z_FULL_FLUSH is not supported currently.
 * Z_BLOCK is not supported currently.
 * Z_TREES is not supported currently.
 */
enum FlushType {
    NoFlush
    | Finish
}

func getFlushValue(flush: FlushType): Int32 {
    return match (flush) {
        case NoFlush => 0
        case Finish => 4
    }
}
