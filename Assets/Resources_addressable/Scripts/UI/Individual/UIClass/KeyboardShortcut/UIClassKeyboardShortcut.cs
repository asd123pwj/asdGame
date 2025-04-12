using System.Collections.Generic;
using UnityEngine;

public class UIClassKeyboardShortcut{
    public UIClassKeyboardShortcut(){
        
        

        UIClass._add("UIRightMenuInteractionManager_KeyShortcut", new UIScrollViewInfo(){
            type = "UIRightMenuInteractionManager_KeyShortcut",
            base_type = "UIRightMenu",
            background_key = "ui_RoundedIcon_32",
            PixelsPerUnitMultiplier = 1,
            prefab_key = "ScrollView",
            // sizeDelta = new (96*1 + 16 + 16, 32*3 + 4*2 + 16 + 16),
            // padding = new RectOffset(16, 16, 16, 16),
            paddingLeft = 16, paddingRight = 16, paddingTop = 16, paddingBottom = 16,
            spacing = new (8, 8),
            // cellSize = new (96, 32),
            maxSize = new (300, 300),
            rightMenu_name = "UIRightMenuInteractionManager_KeyShortcut",
            // constraintCount = 1,
            anchoredPosition = new (8, -8),
            interactions = new List<string>() {
                "UIDrag",
                // "UIDeselectClose"
                "UIOpenRightMenu",
            },
            items = new(){
                new() {
                    type = "UIExecuteCommandFromMessage", sizeDelta = new (196, 32), messageID = "UIExecuteCommand"
                },
                new UIInputFieldInfo() {
                    type = "UIInputField", sizeDelta = new (96, 32), messageID = "UIExecuteCommand"
                },
                new() {
                    type = "UIHighlight_a0.5_ScrollPass2Parent", sizeDelta = new (96, 62),
                },
                new() {
                    type = "UIHighlight_a0.5_ScrollPass2Parent", sizeDelta = new (96, 32),
                },
                new() {
                    type = "UIOpenAttributeManager", sizeDelta = new (196, 32),
                },
            },
            subUIs = new()
        });


        UIClass._add("UIOpenAttributeManager", new (){
            type="UIOpenAttributeManager",
            // base_type="UIAttributeManager",
            background_key="p5", 
            // attributes = new() {
            //     {"command", "toggleUI --useMousePos --type UIAttributeManager" }
            // },
            interactions = new List<string>() {
                // "UISetTop",
                // "UIExecuteCommandFromAttribute",
                "UIOpenAttributeManager",
                "UIScrollPass2Parent"
            },
            // messageID = "UIExecuteCommandFromAttribute"
        });

        UIClass._add("UIExecuteCommandFromAttribute", new (){
            type="UIExecuteCommandFromAttribute",
            background_key="p5", 
            attributes = new() {
                {"COMMAND", "toggleUI --useMousePos --type UIAttributeManager" },
            },
            interactions = new List<string>() {
                // "UISetTop",
                "UIExecuteCommandFromAttribute",
                "UIScrollPass2Parent"
            },
            // messageID = "UIExecuteCommandFromAttribute"
        });

        UIClass._add("UIExecuteCommandFromMessage", new (){
            type="UIExecuteCommandFromMessage",
            background_key="p5", 
            interactions = new List<string>() {
                // "UISetTop",
                "UIExecuteCommandFromMessage",
                "UIScrollPass2Parent"
            },
            messageID = "UIExecuteCommandFromMessage"
        });

        UIClass._add("UIKeyShortcut", new (){
            type="UIKeyShortcut",
            name="UIKeyShortcut", 
            background_key="p5_a0.5", 
            sizeDelta = new(32*2, 32*2), 
            rightMenu_name = "UIRightMenuInteractionManager_KeyShortcut",
            attributes = new() {
                {"COMMAND", "toggleUI --useMousePos --type UIAttributeManager" },
                {"Test一下多个mingling能不can正常place以及分隔符有没有正常显示", "命令名称 --参数名称 参数值 --命令名称能放多长呢 想多长就多长 --test一下长文本 这有13579个字 --123那有七个字的命令啊 abcdefghijklmn" }
            },
            interactions = new List<string>() {
                // "UISetTop",
                "UIOpenRightMenu",
                "UIExecuteCommandFromAttribute",
            },
        });

        UIClass._add("UIKeyboardShortcut", new (){
            type = "UIKeyboardShortcut",
            background_key = "ui_5", 
            // background_key = "ui_TitleBg",
            PixelsPerUnitMultiplier = 1f,
            sizeDelta = new (800*2, 288*2),
            interactions = new List<string>() {
                // "UISetTop",
                "UIDrag",
                // "UIOpenRightMenu",
            },
            // rightMenu_name = "UIRightMenuInteractionManager_KeyboardShortcut",
            subUIs = new(){
                new() { type = "UICloseButtom", sizeDelta = new(16*2, 16*2), anchoredPosition = new(-7*2, -7*2) },
                new() { type = "UIResizeButtom", background_key="", sizeDelta = new(16*2, 16*2), anchoredPosition = new(-7*2, 7*2) },
                new() { type = "UIKeyShortcut", name="key_esc", anchoredPosition = new(11*2, -36*2) },
                new() { type = "UIKeyShortcut", name="key_f1", anchoredPosition = new(83*2, -36*2) },
                new() { type = "UIKeyShortcut", name="key_f2", anchoredPosition = new(119*2, -36*2) },
                new() { type = "UIKeyShortcut", name="key_f3", anchoredPosition = new(155*2, -36*2) },
                new() { type = "UIKeyShortcut", name="key_f4", anchoredPosition = new(191*2, -36*2) },
                new() { type = "UIKeyShortcut", name="key_f5", anchoredPosition = new(236*2, -36*2) },
                new() { type = "UIKeyShortcut", name="key_f6", anchoredPosition = new(272*2, -36*2) },
                new() { type = "UIKeyShortcut", name="key_f7", anchoredPosition = new(308*2, -36*2) },
                new() { type = "UIKeyShortcut", name="key_f8", anchoredPosition = new(344*2, -36*2) },
                new() { type = "UIKeyShortcut", name="key_f9", anchoredPosition = new(389*2, -36*2) },
                new() { type = "UIKeyShortcut", name="key_f10", anchoredPosition = new(425*2, -36*2) },
                new() { type = "UIKeyShortcut", name="key_f11", anchoredPosition = new(461*2, -36*2) },
                new() { type = "UIKeyShortcut", name="key_f12", anchoredPosition = new(497*2, -36*2) },
                new() { type = "UIKeyShortcut", name="key_print screen", anchoredPosition = new(537*2, -36*2) },
                new() { type = "UIKeyShortcut", name="key_scroll lock", anchoredPosition = new(573*2, -36*2) },
                new() { type = "UIKeyShortcut", name="key_pause", anchoredPosition = new(609*2, -36*2) },

                new() { type = "UIKeyShortcut", name="key_`", anchoredPosition = new(11*2, -76*2) },
                new() { type = "UIKeyShortcut", name="key_1", anchoredPosition = new(47*2, -76*2) },
                new() { type = "UIKeyShortcut", name="key_2", anchoredPosition = new(83*2, -76*2) },
                new() { type = "UIKeyShortcut", name="key_3", anchoredPosition = new(119*2, -76*2) },
                new() { type = "UIKeyShortcut", name="key_4", anchoredPosition = new(155*2, -76*2) },
                new() { type = "UIKeyShortcut", name="key_5", anchoredPosition = new(191*2, -76*2) },
                new() { type = "UIKeyShortcut", name="key_6", anchoredPosition = new(227*2, -76*2) },
                new() { type = "UIKeyShortcut", name="key_7", anchoredPosition = new(263*2, -76*2) },
                new() { type = "UIKeyShortcut", name="key_8", anchoredPosition = new(299*2, -76*2) },
                new() { type = "UIKeyShortcut", name="key_9", anchoredPosition = new(335*2, -76*2) },
                new() { type = "UIKeyShortcut", name="key_0", anchoredPosition = new(371*2, -76*2) },
                new() { type = "UIKeyShortcut", name="key_-", anchoredPosition = new(407*2, -76*2) },
                new() { type = "UIKeyShortcut", name="key_=", anchoredPosition = new(443*2, -76*2) },
                new() { type = "UIKeyShortcut", name="key_backspace", sizeDelta = new(50*2, 32*2), anchoredPosition = new(479*2, -76*2) },
                new() { type = "UIKeyShortcut", name="key_insert", anchoredPosition = new(537*2, -76*2) },
                new() { type = "UIKeyShortcut", name="key_home", anchoredPosition = new(573*2, -76*2) },
                new() { type = "UIKeyShortcut", name="key_page up", anchoredPosition = new(609*2, -76*2) },
                new() { type = "UIKeyShortcut", name="key_number lock", anchoredPosition = new(649*2, -76*2) },
                new() { type = "UIKeyShortcut", name="key_numpad /", anchoredPosition = new(685*2, -76*2) },
                new() { type = "UIKeyShortcut", name="key_numpad *", anchoredPosition = new(721*2, -76*2) },
                new() { type = "UIKeyShortcut", name="key_numpad -", anchoredPosition = new(757*2, -76*2) },

                new() { type = "UIKeyShortcut", name="key_tab", sizeDelta = new(50*2, 32*2), anchoredPosition = new(11*2, -112*2) },
                new() { type = "UIKeyShortcut", name="key_q", anchoredPosition = new(65*2, -112*2) },
                new() { type = "UIKeyShortcut", name="key_w", anchoredPosition = new(101*2, -112*2) },
                new() { type = "UIKeyShortcut", name="key_e", anchoredPosition = new(137*2, -112*2) },
                new() { type = "UIKeyShortcut", name="key_r", anchoredPosition = new(173*2, -112*2) },
                new() { type = "UIKeyShortcut", name="key_t", anchoredPosition = new(209*2, -112*2) },
                new() { type = "UIKeyShortcut", name="key_y", anchoredPosition = new(245*2, -112*2) },
                new() { type = "UIKeyShortcut", name="key_u", anchoredPosition = new(281*2, -112*2) },
                new() { type = "UIKeyShortcut", name="key_i", anchoredPosition = new(317*2, -112*2) },
                new() { type = "UIKeyShortcut", name="key_o", anchoredPosition = new(353*2, -112*2) },
                new() { type = "UIKeyShortcut", name="key_p", anchoredPosition = new(389*2, -112*2) },
                new() { type = "UIKeyShortcut", name="key_[", anchoredPosition = new(425*2, -112*2) },
                new() { type = "UIKeyShortcut", name="key_]", anchoredPosition = new(461*2, -112*2) },
                new() { type = "UIKeyShortcut", name="key_\\", anchoredPosition = new(497*2, -112*2) },
                new() { type = "UIKeyShortcut", name="key_delete", anchoredPosition = new(537*2, -112*2) },
                new() { type = "UIKeyShortcut", name="key_end", anchoredPosition = new(573*2, -112*2) },
                new() { type = "UIKeyShortcut", name="key_page down", anchoredPosition = new(609*2, -112*2) },
                new() { type = "UIKeyShortcut", name="key_numpad 7", anchoredPosition = new(649*2, -112*2) },
                new() { type = "UIKeyShortcut", name="key_numpad 8", anchoredPosition = new(685*2, -112*2) },
                new() { type = "UIKeyShortcut", name="key_numpad 9", anchoredPosition = new(721*2, -112*2) },
                new() { type = "UIKeyShortcut", name="key_numpad +", sizeDelta = new(32*2, 68*2), anchoredPosition = new(757*2, -112*2) },

                new() { type = "UIKeyShortcut", name="key_caps lock", sizeDelta = new(68*2, 32*2), anchoredPosition = new(11*2, -148*2) },
                new() { type = "UIKeyShortcut", name="key_a", anchoredPosition = new(83*2, -148*2) },
                new() { type = "UIKeyShortcut", name="key_s", anchoredPosition = new(119*2, -148*2) },
                new() { type = "UIKeyShortcut", name="key_d", anchoredPosition = new(155*2, -148*2) },
                new() { type = "UIKeyShortcut", name="key_f", anchoredPosition = new(191*2, -148*2) },
                new() { type = "UIKeyShortcut", name="key_g", anchoredPosition = new(227*2, -148*2) },
                new() { type = "UIKeyShortcut", name="key_h", anchoredPosition = new(263*2, -148*2) },
                new() { type = "UIKeyShortcut", name="key_j", anchoredPosition = new(299*2, -148*2) },
                new() { type = "UIKeyShortcut", name="key_k", anchoredPosition = new(335*2, -148*2) },
                new() { type = "UIKeyShortcut", name="key_l", anchoredPosition = new(371*2, -148*2) },
                new() { type = "UIKeyShortcut", name="key_;", anchoredPosition = new(407*2, -148*2) },
                new() { type = "UIKeyShortcut", name="key_'", anchoredPosition = new(443*2, -148*2) },
                new() { type = "UIKeyShortcut", name="key_enter", sizeDelta = new(50*2, 32*2), anchoredPosition = new(479*2, -148*2) },
                new() { type = "UIKeyShortcut", name="key_numpad 4", anchoredPosition = new(649*2, -148*2) },
                new() { type = "UIKeyShortcut", name="key_numpad 5", anchoredPosition = new(685*2, -148*2) },
                new() { type = "UIKeyShortcut", name="key_numpad 6", anchoredPosition = new(721*2, -148*2) },

                new() { type = "UIKeyShortcut", name="key_left shift", sizeDelta = new(86*2, 32*2), anchoredPosition = new(11*2, -184*2) },
                new() { type = "UIKeyShortcut", name="key_z", anchoredPosition = new(101*2, -184*2) },
                new() { type = "UIKeyShortcut", name="key_x", anchoredPosition = new(137*2, -184*2) },
                new() { type = "UIKeyShortcut", name="key_c", anchoredPosition = new(173*2, -184*2) },
                new() { type = "UIKeyShortcut", name="key_v", anchoredPosition = new(209*2, -184*2) },
                new() { type = "UIKeyShortcut", name="key_b", anchoredPosition = new(245*2, -184*2) },
                new() { type = "UIKeyShortcut", name="key_n", anchoredPosition = new(281*2, -184*2) },
                new() { type = "UIKeyShortcut", name="key_m", anchoredPosition = new(317*2, -184*2) },
                new() { type = "UIKeyShortcut", name="key_,", anchoredPosition = new(353*2, -184*2) },
                new() { type = "UIKeyShortcut", name="key_.", anchoredPosition = new(389*2, -184*2) },
                new() { type = "UIKeyShortcut", name="key_/", anchoredPosition = new(425*2, -184*2) },
                new() { type = "UIKeyShortcut", name="key_right shift", sizeDelta = new(68*2, 32*2), anchoredPosition = new(461*2, -184*2) },
                new() { type = "UIKeyShortcut", name="key_up", anchoredPosition = new(573*2, -184*2) },
                new() { type = "UIKeyShortcut", name="key_numpad 1", anchoredPosition = new(649*2, -184*2) },
                new() { type = "UIKeyShortcut", name="key_numpad 2", anchoredPosition = new(685*2, -184*2) },
                new() { type = "UIKeyShortcut", name="key_numpad 3", anchoredPosition = new(721*2, -184*2) },
                new() { type = "UIKeyShortcut", name="key_numpad enter", sizeDelta = new(32*2, 68*2), anchoredPosition = new(757*2, -184*2) },

                new() { type = "UIKeyShortcut", name="key_left ctrl", sizeDelta = new(50*2, 32*2), anchoredPosition = new(11*2, -220*2) },
                new() { type = "UIKeyShortcut", name="key_windows", sizeDelta = new(50*2, 32*2), anchoredPosition = new(65*2, -220*2) },
                new() { type = "UIKeyShortcut", name="key_left alt", sizeDelta = new(50*2, 32*2), anchoredPosition = new(119*2, -220*2) },
                new() { type = "UIKeyShortcut", name="key_space", sizeDelta = new(194*2, 32*2), anchoredPosition = new(173*2, -220*2) },
                new() { type = "UIKeyShortcut", name="key_right alt", sizeDelta = new(50*2, 32*2), anchoredPosition = new(371*2, -220*2) },
                new() { type = "UIKeyShortcut", name="key_menu", sizeDelta = new(50*2, 32*2), anchoredPosition = new(425*2, -220*2) },
                new() { type = "UIKeyShortcut", name="key_right ctrl", sizeDelta = new(50*2, 32*2), anchoredPosition = new(479*2, -220*2) },
                new() { type = "UIKeyShortcut", name="key_left", anchoredPosition = new(537*2, -220*2) },
                new() { type = "UIKeyShortcut", name="key_down", anchoredPosition = new(573*2, -220*2) },
                new() { type = "UIKeyShortcut", name="key_right", anchoredPosition = new(609*2, -220*2) },
                new() { type = "UIKeyShortcut", name="key_numpad 0", sizeDelta = new(68*2, 32*2), anchoredPosition = new(649*2, -220*2) },
                new() { type = "UIKeyShortcut", name="key_numpad .", anchoredPosition = new(721*2, -220*2) },


            },
        });

    }
}