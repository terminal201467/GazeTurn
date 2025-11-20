//
//  InstrumentType.swift
//  GazeTurn
//
//  Created by Claude Code on 2025/3/20.
//

import Foundation

/// 樂器類型枚舉，定義所有支援的樂器類別
enum InstrumentType: String, CaseIterable, Codable {
    case stringInstruments = "string_instruments"
    case woodwindBrass = "woodwind_brass"
    case keyboard = "keyboard"
    case pluckedStrings = "plucked_strings"
    case percussion = "percussion"
    case vocal = "vocal"
    case custom = "custom"

    /// 樂器類型的顯示名稱
    var displayName: String {
        switch self {
        case .stringInstruments:
            return "弦樂器"
        case .woodwindBrass:
            return "管樂器"
        case .keyboard:
            return "鍵盤樂器"
        case .pluckedStrings:
            return "撥弦樂器"
        case .percussion:
            return "打擊樂器"
        case .vocal:
            return "聲樂"
        case .custom:
            return "自定義"
        }
    }

    /// 樂器類型的英文名稱
    var displayNameEN: String {
        switch self {
        case .stringInstruments:
            return "String Instruments"
        case .woodwindBrass:
            return "Woodwind/Brass"
        case .keyboard:
            return "Keyboard"
        case .pluckedStrings:
            return "Plucked Strings"
        case .percussion:
            return "Percussion"
        case .vocal:
            return "Vocal"
        case .custom:
            return "Custom"
        }
    }

    /// 樂器類型的描述
    var description: String {
        switch self {
        case .stringInstruments:
            return "小提琴、中提琴、大提琴等需要固定頭部的樂器"
        case .woodwindBrass:
            return "長笛、單簧管、小號、長號、薩克斯風等嘴部固定的樂器"
        case .keyboard:
            return "鋼琴、電子琴、管風琴等頭部完全自由的樂器"
        case .pluckedStrings:
            return "吉他、貝斯、烏克麗麗等可能隨節奏搖頭的樂器"
        case .percussion:
            return "爵士鼓、馬林巴、定音鼓等打擊樂器"
        case .vocal:
            return "聲樂演唱"
        case .custom:
            return "自定義控制模式"
        }
    }

    /// 樂器類型的英文描述
    var descriptionEN: String {
        switch self {
        case .stringInstruments:
            return "Violin, Viola, Cello - Head must remain fixed"
        case .woodwindBrass:
            return "Flute, Clarinet, Trumpet, Trombone, Saxophone - Mouth position fixed"
        case .keyboard:
            return "Piano, Keyboard, Organ - Complete head freedom"
        case .pluckedStrings:
            return "Guitar, Bass, Ukulele - May move head with rhythm"
        case .percussion:
            return "Drums, Marimba, Timpani - Variable playing posture"
        case .vocal:
            return "Vocal performance"
        case .custom:
            return "Fully customizable control mode"
        }
    }

    /// 樂器範例列表
    var examples: [String] {
        switch self {
        case .stringInstruments:
            return ["小提琴 (Violin)", "中提琴 (Viola)", "大提琴 (Cello)"]
        case .woodwindBrass:
            return ["長笛 (Flute)", "單簧管 (Clarinet)", "小號 (Trumpet)", "長號 (Trombone)", "薩克斯風 (Saxophone)"]
        case .keyboard:
            return ["鋼琴 (Piano)", "電子琴 (Keyboard)", "管風琴 (Organ)"]
        case .pluckedStrings:
            return ["吉他 (Guitar)", "貝斯 (Bass)", "烏克麗麗 (Ukulele)"]
        case .percussion:
            return ["爵士鼓 (Drums)", "馬林巴 (Marimba)", "定音鼓 (Timpani)"]
        case .vocal:
            return ["聲樂演唱 (Vocal Performance)"]
        case .custom:
            return ["自定義模式 (Custom Mode)"]
        }
    }

    /// SF Symbols 圖示名稱
    var iconName: String {
        switch self {
        case .stringInstruments:
            return "music.note"
        case .woodwindBrass:
            return "music.mic"
        case .keyboard:
            return "pianokeys"
        case .pluckedStrings:
            return "guitars"
        case .percussion:
            return "music.quarternote.3"
        case .vocal:
            return "music.mic.circle"
        case .custom:
            return "slider.horizontal.3"
        }
    }

    /// 推薦的控制方式說明
    var controlModeDescription: String {
        switch self {
        case .stringInstruments:
            return "眨眼控制：雙眨眼=下一頁，長眨眼=上一頁"
        case .woodwindBrass:
            return "混合控制：輕微搖頭 + 眨眼確認"
        case .keyboard:
            return "搖頭控制：左搖=上一頁，右搖=下一頁"
        case .pluckedStrings:
            return "搖頭控制：刻意緩慢搖頭（避免誤觸發）"
        case .percussion:
            return "可選模式：搖頭或眨眼"
        case .vocal:
            return "搖頭控制：明確左右搖"
        case .custom:
            return "完全自定義"
        }
    }

    /// 控制方式英文說明
    var controlModeDescriptionEN: String {
        switch self {
        case .stringInstruments:
            return "Blink: Double blink=next, Long blink=previous"
        case .woodwindBrass:
            return "Hybrid: Slight head shake + blink confirmation"
        case .keyboard:
            return "Head shake: Left=previous, Right=next"
        case .pluckedStrings:
            return "Head shake: Deliberate slow shake (avoid false triggers)"
        case .percussion:
            return "User choice: Head shake OR blink"
        case .vocal:
            return "Head shake: Clear left/right shake"
        case .custom:
            return "Fully customizable"
        }
    }
}
