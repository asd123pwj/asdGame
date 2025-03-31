using UnityEngine;
using UnityEngine.UI;
using System.Collections.Generic;
using UnityEngine.EventSystems;
using Newtonsoft.Json;
using System.Reflection;
using System.Linq;
using System;
using Force.DeepCloner;

public class UIClass{
    public static Dictionary<string, UIInfo> _UIInfos = new();

    // static Dictionary<string, UIInfo> UIInfos { get { return get_all_UIInfo(); } }
    // readonly public static UIInfo UICommandWindow = new(){
    //     type = "UICommandWindow",
    //     background_key = "ui_1", 
    //     sizeDelta = new(800, 400),
    //     interactions = new List<string>() {
    //         "UISetTop",
    //         "UIDrag",
    //     },
    //     subUIs = new(){
    //         new() { type = "UICloseButtom", sizeDelta = new(25, 25)},
    //         new() { type = "UIResizeButtom", sizeDelta = new(25, 25)},
    //         new UIInputFieldInfo() { type = "UIInputField", sizeDelta = new(800-25-2*2, 25-2*2),
    //                 pivot = new(0, 0), anchorMin = new(0, 0), anchorMax = new(0, 0),
    //                 anchoredPosition = new(2, 2), PixelsPerUnitMultiplier=4,
    //                 messageID = "COMMAND",
    //         },
    //         new UIScrollTextInfo() { type = "UIScrollText", 
    //             sizeDelta = new(800-25, 400-25*2-12.5f*2), anchoredPosition = new(12.5f, -(25+12.5f)),
    //             messageID = "COMMAND",
    //         },
    //     },
    // };
    // readonly public static UIInfo UIBackpack = new() {
    //     type = "UIBackpack",
    //     // base_type = "UIBase",
    //     background_key = "ui_1",
    //     sizeDelta = new(1600, 900), 
    //     subUIs = new(){
    //         new() { type = "UICloseButtom" },
    //         new() { type = "UIResizeButtom" },
    //     },
    //     interactions = new List<string>() {
    //         "UISetTop",
    //         "UIDrag",
    //         "UIOpenRightMenu",
    //         "UIClickCloseRightMenu",
    //     },
    // };
    // readonly public static UIInfo UICloseButtom = new() {
    //     type = "UICloseButtom",
    //     background_key = "ui_3_16",
    //     anchorMin = new(1, 1), anchorMax = new(1, 1), pivot = new (1, 1), 
    //     sizeDelta = new(16, 16),
    //     interactions = new List<string>() {
    //         "UIClickClose",
    //     },
    // };
    // readonly public static UIInfo UIToggleButtom = new() {
    //     type = "UIToggleButtom",
    //     background_key = "Empty",
    //     sizeDelta = new (120, 40),
    //     interactions = new List<string>() {
    //         "UIToggle",
    //     },
    // // };
    // readonly public static UIInfo UIResizeButtom = new() {
    //     type = "UIResizeButtom",
    //     background_key = "ui_4_16",
    //     anchorMin = new(1, 0), anchorMax = new(1, 0), pivot = new (1, 0), 
    //     sizeDelta = new (16, 16),
    //     interactions = new List<string>() {
    //         "UISetTop",
    //         "UIResizeScaleConstrait",
    //     },
    // };
    // readonly public static UIScrollTextInfo UIScrollText = new(){
    //     type = "UIScrollText",
    //     base_type = "UIScrollText",
    //     prefab_key = "ScrollText",
    //     background_key = "ui_2", PixelsPerUnitMultiplier=2,
    //     // sizeDelta = new(0, 0),
    //     // anchorMin = new(0.01f, 0.01f), anchorMax = new(0.99f, 0.99f), pivot = new (0.5f, 0.5f), 
    //     enableNavigation = true,
    //     interactions = new List<string>() {
    //         "UISetTop",
    //     },
    // };
    // readonly public static UIInfo UIImage = new(){
    //     type = "UIImage", //sizeDelta = new(0, 0),
    //     // anchorMin = new(0, 0), anchorMax = new(0, 1), pivot = new (0.5f, 0.5f), 
    //     interactions = new List<string>() {
    //         "UISetTop",
    //     },
    // };
    // readonly public static UIInfo UIRightMenu = new() {
    //     type = "UIRightMenu",
    //     background_key = "RightMenu",
    //     enableNavigation = true,
    //     sizeDelta = new (300, 200),
    //     interactions = new List<string>() {
    //         "UISetTop",
    //         "UIDeselectClose",
    //     },
    // };
    // readonly public static UIInfo UIRightMenuInteractionManager = new() {
    //     type = "UIRightMenuInteractionManager",
    //     base_type = "UIRightMenu",
    //     background_key = "RightMenu",
    //     enableNavigation = true,
    //     sizeDelta = new (190 + 40, 230 + 40),
    //     interactions = new List<string>() {
    //         "UISetTop",
    //         // "UIDeselectClose",
    //     },
    //     subUIs = new(){
    //         new UIScrollViewInfo() {
    //             type = "UIScrollView",
    //             base_type = "UIScrollView",
    //             sizeDelta = new (150*1 + 20*0 + 20 + 20, 50*3 + 20*2 + 20 + 20),
    //             cellSize = new (150, 50),
    //             constraintCount = 1,
    //             anchoredPosition = new (20, -20),
    //             interactions = new List<string>() {
    //                 "UISetTop",
    //             },
    //             items = new(){
    //                 new() {
    //                     name = "UIImage",
    //                     type = "UIImage",
    //                 },
    //                 // new() {
    //                 //     name = "UIToggleSubUI-UICloseButtom",
    //                 //     type = "UIToggleButtom",
    //                 // },
    //             },
    //             subUIs = new()
    //         }
    //     }
    // };
    // readonly public static UIInfo UIContainer = new() {
    //     type = "UIContainer",
    //     background_key = "Empty",
    //     sizeDelta = new (800, 800),
    //     interactions = new List<string>() {
    //         "UISetTop",
    //         "UIDrop",
    //     },
    // };
    // readonly public static UIInputFieldInfo UIInputField = new() {
    //     type = "UIInputField",
    //     base_type = "UIInputField",
    //     prefab_key = "InputField",
    //     background_key = "ui_2", PixelsPerUnitMultiplier=8, 
    //     sizeDelta = new (400, 50),
    //     enableNavigation = true,
    //     interactions = new List<string>() {
    //         "UISetTop",
    //         "UISubmit",
    //         // "UIDrag",
    //     }
    // };
    // readonly public static UIInfo UIKeyboardShortcut = new() {
    //     type = "UIKeyboardShortcut",
    //     background_key = "ui_5", 
    //     sizeDelta = new (800*2, 288*2),
    //     interactions = new List<string>() {
    //         "UISetTop",
    //         "UIDrag",
    //         "UIOpenRightMenu",
    //     },
    //     subUIs = new(){
    //         new() { type = "UICloseButtom", sizeDelta = new(16*2, 16*2), anchoredPosition = new(-7*2, -7*2) },
    //         new() { type = "UIResizeButtom", background_key="", sizeDelta = new(16*2, 16*2), anchoredPosition = new(-7*2, 7*2) },
    //         new() { type = "UIImage", name="key_esc", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(11*2, -36*2) },
    //         new() { type = "UIImage", name="key_f1", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(83*2, -36*2) },
    //         new() { type = "UIImage", name="key_f2", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(119*2, -36*2) },
    //         new() { type = "UIImage", name="key_f3", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(155*2, -36*2) },
    //         new() { type = "UIImage", name="key_f4", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(191*2, -36*2) },
    //         new() { type = "UIImage", name="key_f5", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(236*2, -36*2) },
    //         new() { type = "UIImage", name="key_f6", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(272*2, -36*2) },
    //         new() { type = "UIImage", name="key_f7", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(308*2, -36*2) },
    //         new() { type = "UIImage", name="key_f8", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(344*2, -36*2) },
    //         new() { type = "UIImage", name="key_f9", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(389*2, -36*2) },
    //         new() { type = "UIImage", name="key_f10", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(425*2, -36*2) },
    //         new() { type = "UIImage", name="key_f11", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(461*2, -36*2) },
    //         new() { type = "UIImage", name="key_f12", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(497*2, -36*2) },
    //         new() { type = "UIImage", name="key_print screen", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(537*2, -36*2) },
    //         new() { type = "UIImage", name="key_scroll lock", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(573*2, -36*2) },
    //         new() { type = "UIImage", name="key_pause", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(609*2, -36*2) },

    //         new() { type = "UIImage", name="key_`", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(11*2, -76*2) },
    //         new() { type = "UIImage", name="key_1", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(47*2, -76*2) },
    //         new() { type = "UIImage", name="key_2", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(83*2, -76*2) },
    //         new() { type = "UIImage", name="key_3", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(119*2, -76*2) },
    //         new() { type = "UIImage", name="key_4", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(155*2, -76*2) },
    //         new() { type = "UIImage", name="key_5", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(191*2, -76*2) },
    //         new() { type = "UIImage", name="key_6", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(227*2, -76*2) },
    //         new() { type = "UIImage", name="key_7", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(263*2, -76*2) },
    //         new() { type = "UIImage", name="key_8", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(299*2, -76*2) },
    //         new() { type = "UIImage", name="key_9", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(335*2, -76*2) },
    //         new() { type = "UIImage", name="key_0", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(371*2, -76*2) },
    //         new() { type = "UIImage", name="key_-", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(407*2, -76*2) },
    //         new() { type = "UIImage", name="key_=", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(443*2, -76*2) },
    //         new() { type = "UIImage", name="key_backspace", background_key="p5_a0.5", sizeDelta = new(50*2, 32*2), anchoredPosition = new(479*2, -76*2) },
    //         new() { type = "UIImage", name="key_insert", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(537*2, -76*2) },
    //         new() { type = "UIImage", name="key_home", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(573*2, -76*2) },
    //         new() { type = "UIImage", name="key_page up", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(609*2, -76*2) },
    //         new() { type = "UIImage", name="key_number lock", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(649*2, -76*2) },
    //         new() { type = "UIImage", name="key_numpad /", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(685*2, -76*2) },
    //         new() { type = "UIImage", name="key_numpad *", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(721*2, -76*2) },
    //         new() { type = "UIImage", name="key_numpad -", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(757*2, -76*2) },

    //         new() { type = "UIImage", name="key_tab", background_key="p5_a0.5", sizeDelta = new(50*2, 32*2), anchoredPosition = new(11*2, -112*2) },
    //         new() { type = "UIImage", name="key_q", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(65*2, -112*2) },
    //         new() { type = "UIImage", name="key_w", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(101*2, -112*2) },
    //         new() { type = "UIImage", name="key_e", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(137*2, -112*2) },
    //         new() { type = "UIImage", name="key_r", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(173*2, -112*2) },
    //         new() { type = "UIImage", name="key_t", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(209*2, -112*2) },
    //         new() { type = "UIImage", name="key_y", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(245*2, -112*2) },
    //         new() { type = "UIImage", name="key_u", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(281*2, -112*2) },
    //         new() { type = "UIImage", name="key_i", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(317*2, -112*2) },
    //         new() { type = "UIImage", name="key_o", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(353*2, -112*2) },
    //         new() { type = "UIImage", name="key_p", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(389*2, -112*2) },
    //         new() { type = "UIImage", name="key_[", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(425*2, -112*2) },
    //         new() { type = "UIImage", name="key_]", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(461*2, -112*2) },
    //         new() { type = "UIImage", name="key_\\", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(497*2, -112*2) },
    //         new() { type = "UIImage", name="key_delete", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(537*2, -112*2) },
    //         new() { type = "UIImage", name="key_end", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(573*2, -112*2) },
    //         new() { type = "UIImage", name="key_page down", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(609*2, -112*2) },
    //         new() { type = "UIImage", name="key_numpad 7", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(649*2, -112*2) },
    //         new() { type = "UIImage", name="key_numpad 8", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(685*2, -112*2) },
    //         new() { type = "UIImage", name="key_numpad 9", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(721*2, -112*2) },
    //         new() { type = "UIImage", name="key_numpad +", background_key="p5_a0.5", sizeDelta = new(32*2, 68*2), anchoredPosition = new(757*2, -112*2) },

    //         new() { type = "UIImage", name="key_caps lock", background_key="p5_a0.5", sizeDelta = new(68*2, 32*2), anchoredPosition = new(11*2, -148*2) },
    //         new() { type = "UIImage", name="key_a", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(83*2, -148*2) },
    //         new() { type = "UIImage", name="key_s", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(119*2, -148*2) },
    //         new() { type = "UIImage", name="key_d", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(155*2, -148*2) },
    //         new() { type = "UIImage", name="key_f", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(191*2, -148*2) },
    //         new() { type = "UIImage", name="key_g", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(227*2, -148*2) },
    //         new() { type = "UIImage", name="key_h", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(263*2, -148*2) },
    //         new() { type = "UIImage", name="key_j", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(299*2, -148*2) },
    //         new() { type = "UIImage", name="key_k", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(335*2, -148*2) },
    //         new() { type = "UIImage", name="key_l", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(371*2, -148*2) },
    //         new() { type = "UIImage", name="key_;", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(407*2, -148*2) },
    //         new() { type = "UIImage", name="key_'", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(443*2, -148*2) },
    //         new() { type = "UIImage", name="key_enter", background_key="p5_a0.5", sizeDelta = new(50*2, 32*2), anchoredPosition = new(479*2, -148*2) },
    //         new() { type = "UIImage", name="key_numpad 4", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(649*2, -148*2) },
    //         new() { type = "UIImage", name="key_numpad 5", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(685*2, -148*2) },
    //         new() { type = "UIImage", name="key_numpad 6", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(721*2, -148*2) },

    //         new() { type = "UIImage", name="key_left shift", background_key="p5_a0.5", sizeDelta = new(86*2, 32*2), anchoredPosition = new(11*2, -184*2) },
    //         new() { type = "UIImage", name="key_z", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(101*2, -184*2) },
    //         new() { type = "UIImage", name="key_x", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(137*2, -184*2) },
    //         new() { type = "UIImage", name="key_c", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(173*2, -184*2) },
    //         new() { type = "UIImage", name="key_v", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(209*2, -184*2) },
    //         new() { type = "UIImage", name="key_b", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(245*2, -184*2) },
    //         new() { type = "UIImage", name="key_n", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(281*2, -184*2) },
    //         new() { type = "UIImage", name="key_m", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(317*2, -184*2) },
    //         new() { type = "UIImage", name="key_,", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(353*2, -184*2) },
    //         new() { type = "UIImage", name="key_.", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(389*2, -184*2) },
    //         new() { type = "UIImage", name="key_/", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(425*2, -184*2) },
    //         new() { type = "UIImage", name="key_right shift", background_key="p5_a0.5", sizeDelta = new(68*2, 32*2), anchoredPosition = new(461*2, -184*2) },
    //         new() { type = "UIImage", name="key_up", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(573*2, -184*2) },
    //         new() { type = "UIImage", name="key_numpad 1", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(649*2, -184*2) },
    //         new() { type = "UIImage", name="key_numpad 2", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(685*2, -184*2) },
    //         new() { type = "UIImage", name="key_numpad 3", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(721*2, -184*2) },
    //         new() { type = "UIImage", name="key_numpad enter", background_key="p5_a0.5", sizeDelta = new(32*2, 68*2), anchoredPosition = new(757*2, -184*2) },

    //         new() { type = "UIImage", name="key_left ctrl", background_key="p5_a0.5", sizeDelta = new(50*2, 32*2), anchoredPosition = new(11*2, -220*2) },
    //         new() { type = "UIImage", name="key_windows", background_key="p5_a0.5", sizeDelta = new(50*2, 32*2), anchoredPosition = new(65*2, -220*2) },
    //         new() { type = "UIImage", name="key_left alt", background_key="p5_a0.5", sizeDelta = new(50*2, 32*2), anchoredPosition = new(119*2, -220*2) },
    //         new() { type = "UIImage", name="key_space", background_key="p5_a0.5", sizeDelta = new(194*2, 32*2), anchoredPosition = new(173*2, -220*2) },
    //         new() { type = "UIImage", name="key_right alt", background_key="p5_a0.5", sizeDelta = new(50*2, 32*2), anchoredPosition = new(371*2, -220*2) },
    //         new() { type = "UIImage", name="key_menu", background_key="p5_a0.5", sizeDelta = new(50*2, 32*2), anchoredPosition = new(425*2, -220*2) },
    //         new() { type = "UIImage", name="key_right ctrl", background_key="p5_a0.5", sizeDelta = new(50*2, 32*2), anchoredPosition = new(479*2, -220*2) },
    //         new() { type = "UIImage", name="key_left", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(537*2, -220*2) },
    //         new() { type = "UIImage", name="key_down", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(573*2, -220*2) },
    //         new() { type = "UIImage", name="key_right", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(609*2, -220*2) },
    //         new() { type = "UIImage", name="key_numpad 0", background_key="p5_a0.5", sizeDelta = new(68*2, 32*2), anchoredPosition = new(649*2, -220*2) },
    //         new() { type = "UIImage", name="key_numpad .", background_key="p5_a0.5", sizeDelta = new(32*2, 32*2), anchoredPosition = new(721*2, -220*2) },


    //     },
    // };
    // readonly public static UIScrollViewInfo UIScrollView = new() {
    //     type = "UIScrollView",
    //     base_type = "UIScrollView",
    //     prefab_key = "ScrollView",
    //     background_key = "Empty",
    //     // anchorMin = new(0, 1), anchorMax = new(0, 1), pivot = new(0, 1), localScale = new(1, 1), rotation = new(0, 0, 0, 1),
    //     sizeDelta = new(620, 240),
    //     constraintCount = 3,
    //     subUIs = new(){
    //         new() { type = "UICloseButtom" },
    //         new() { type = "UIResizeButtom" },
    //     },
    //     // subUIs = new Dictionary<string, List<UIInfo>>(){
    //     //     { "ControlUIs", new (){
    //     //         new() { type = "UICloseButtom" },
    //     //         new() { type = "UIResizeButtom" },
    //     //     } },
    //     // },
    //     interactions = new List<string>() {
    //         "UISetTop",
    //         "UIDrag",
    //     },
    // };
    // readonly public static UIInfo UIThumbnail = new() {
    //     type = "UIThumbnail",
    //     base_type = "UIThumbnail",
    //     interactions = new List<string>() {
    //         "UISetTop",
    //         "UIDragInstantiate",
    //     },
    // };


    public static void _add(string name, UIInfo info){
        _UIInfos[name] = info;
    }

    // static Dictionary<string, UIInfo> get_all_UIInfo(){
    //     FieldInfo[] fields = typeof(UIClass).GetFields(BindingFlags.Static | BindingFlags.Public);
    //     Dictionary<string, UIInfo> UIInfos = new();

    //     foreach (var field in fields){
    //         if (field.FieldType != typeof(UIInfo)) continue;
    //         UIInfo info = (UIInfo)field.GetValue(null);
    //         if (info == null) continue;
    //         UIInfo info_ = (UIInfo)field.GetValue(null);
    //         UIInfos[info_.type] = info_;
    //     }
    //     foreach (string name in _UIInfos.Keys){
    //         UIInfos[name] = _UIInfos[name];
    //     }
    //     return UIInfos;
    // }

    

    public static UIInfo _set_default(string type, string name){
        UIInfo info = _set_default(type);
        if (name != ""){
            info.name = name;
        }
        return info;
    }
    public static UIInfo _set_default(Type type, UIInfo info = null){
        return _set_default(type.Name, info);
    }
    public static UIInfo _set_default(string type, UIInfo info=null){
        UIInfo info_ = info ?? _UIInfos[type];
        if (info == null){
            // info_ = UIInfos[type].Copy();
            info_ = _UIInfos[type].DeepClone();
        }
        if (info != null){
            info_ = cover_default(info_);
        }
        // info_ = info_.Copy();
        if (info_.name == ""){
            info_.name = info_.type;
        }
        
        return info_;
    }
    static UIInfo cover_default(UIInfo new_UIInfo){
        UIInfo base_UIInfo = _UIInfos[new_UIInfo.type];
        UIInfo cover_UIInfo =  inherit(base_UIInfo, new_UIInfo);
        // UIInfo subClass_UIInfo = convert_baseClass_to_subClass(cover_UIInfo, base_UIInfo);
        return cover_UIInfo;
    }

    static T inherit<T>(T base_UIInfo, T new_UIInfo){
        Type type = base_UIInfo.GetType();
        while (type != typeof(object)){
            var fields = type.GetFields(BindingFlags.NonPublic | BindingFlags.Instance);
            foreach (var field in fields){
                var baseValue = field.GetValue(base_UIInfo);
                var newValue = field.GetValue(new_UIInfo);
                if (newValue == null){
                    field.SetValueDirect(__makeref(new_UIInfo), baseValue);
                }
            }
            type = type.BaseType;
        }
        // return new_UIInfo.Copy();
        return new_UIInfo.DeepClone();
    }

    static UIInfo convert_baseClass_to_subClass(UIInfo base_UIInfo, UIInfo sub_UIInfo){
        if (sub_UIInfo == null || (base_UIInfo.GetType() == sub_UIInfo.GetType()))
            return base_UIInfo;
        OverwriteBaseValuesToSubClass(base_UIInfo, sub_UIInfo);
        return sub_UIInfo;
    }
    static void OverwriteBaseValuesToSubClass<TBase, TSub>(TBase baseObject, TSub subObject) where TBase : class where TSub : TBase{
        if (baseObject == null){
            throw new ArgumentNullException(nameof(baseObject));
        }

        if (subObject == null){
            throw new ArgumentNullException(nameof(subObject));
        }

        Type baseType = typeof(TBase);
        Type subType = typeof(TSub);

        // Copy all fields from baseObject to subObject
        foreach (var field in baseType.GetFields(BindingFlags.NonPublic | BindingFlags.Instance | BindingFlags.Public)){
            var subField = subType.GetField(field.Name, BindingFlags.NonPublic | BindingFlags.Instance | BindingFlags.Public);
            if (subField != null){
                var value = field.GetValue(baseObject);
                subField.SetValue(subObject, value);
            }
        }

        // Copy all properties from baseObject to subObject
        foreach (var prop in baseType.GetProperties(BindingFlags.NonPublic | BindingFlags.Instance | BindingFlags.Public)){
            var subProp = subType.GetProperty(prop.Name, BindingFlags.NonPublic | BindingFlags.Instance | BindingFlags.Public);
            if (subProp != null && subProp.CanWrite){
                var value = prop.GetValue(baseObject);
                subProp.SetValue(subObject, value);
            }
        }
    }
}
