using System;
using System.Collections.Generic;
using UnityEngine;


class UIKeyRepeater{
    public string name;
    public Vector2 pos;
    public Vector2 size;
    public string cmdName;
    public string shortName;

    public UIKeyRepeater(string name, Vector2 pos, Vector2 size, string cmdName, string shortName){
        this.name = name;
        this.pos = pos;
        this.size = size;
        this.cmdName = cmdName;
        this.shortName = shortName;
    }
}


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
            background_key="p5", 
            interactions = new List<string>() {
                "UIOpenAttributeManager",
                "UIScrollPass2Parent"
            },
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

        // UIClass._add("UIKeyShortcut", new (){
        //     type="UIKeyShortcut",
        //     name="UIKeyShortcut", 
        //     background_key="p5_a0.5", 
        //     sizeDelta = new(32*2, 32*2), 
        //     rightMenu_name = "UIRightMenuInteractionManager_KeyShortcut",
        //     attributes = new() {
        //         {"COMMAND", "UIToggle --useMousePos --type UIAttributeManager" },
        //         {"Test一下多个mingling能不can正常place以及分隔符有没有正常显示", "命令名称 --参数名称 参数值 --命令名称能放多长呢 想多长就多长 --test一下长文本 这有13579个字 --123那有七个字的命令啊 abcdefghijklmn" }
        //     },
        //     interactions = new List<string>() {
        //         // "UISetTop",
        //         "UIOpenRightMenu",
        //         "UIExecuteCommandFromAttribute",
        //         "UIPassMouseLeftDown2Parent",
        //     },
        // });
        

        UIClass._add("UIKey", new (){
            type="UIKey", background_key="ui_RoundedIcon_16", PixelsPerUnitMultiplier=1,
            rightMenu_name = "UIRightMenuInteractionManager_KeyShortcut",
            interactions = new () {
                "UIOpenRightMenu", 
                "UIExecuteCommandFromAttribute",
                "UIPassBeginDrag2Parent", 
                "UIPassEndDrag2Parent",
                "UIPassDrag2Parent",
                "UIPassPointerDown2Parent",
            },
            subUIs = new(){
                new UIScrollTextInfo(){ type = "UIKeyName", text = "Esc", },
                new UIScrollTextInfo(){ type = "UIKeyDescription", text = "占位符", },
            }
        });

        UIClass._add("UIKeyName", new UIScrollTextInfo(){
            type = "UIKeyName", base_type = "UIScrollText",
            fontSize = 16, marginTop=0, marginBottom=0, marginLeft=4, marginRight=0, 
            minSize = new(24, 24), maxSize = new(128, 24), anchoredPosition= new(6, -8), 
            prefab_key = "ScrollText", background_key = "",
            interactions = new() {
                "UIPassBeginDrag2Parent", 
                "UIPassEndDrag2Parent",
                "UIPassDrag2Parent",
                "UIPassPointerDown2Parent",
            }
        });
        
        UIClass._add("UIKeyDescription", new UIScrollTextInfo(){
            type = "UIKeyDescription", base_type = "UIScrollText",
            fontSize = 16, marginTop=0, marginBottom=0, marginLeft=4, marginRight=0, 
            minSize = new(32, 24), maxSize = new(60, 24), anchoredPosition= new(6, -32), 
            prefab_key = "ScrollText", background_key = "",
            interactions = new() {
                "UIPassBeginDrag2Parent", 
                "UIPassEndDrag2Parent",
                "UIPassDrag2Parent",
                "UIPassPointerDown2Parent",
            }
        });

        Vector2 keySize_small = new(32*2, 32*2);
        Vector2 keySize_middle = new(50*2, 32*2);
        Vector2 keySize_large = new(68*2, 32*2);
        Vector2 keySize_large_T = new(32*2, 68*2);
        Vector2 keySize_huge = new(86*2, 32*2);
        Vector2 keySize_veryHuge = new(194*2, 32*2);

        float row1 = -36*2;
        float row2 = -76*2;
        float row3 = -112*2;
        float row4 = -148*2;
        float row5 = -184*2;
        float row6 = -220*2;

        Dictionary<string, UIKeyRepeater> keys_infos = new (){
            { "escape", new UIKeyRepeater("escape", new(11*2, row1), keySize_small.Copy(), "escape", "Esc") },
            { "f1", new UIKeyRepeater("f1", new(83*2, row1), keySize_small.Copy(), "f1", "F1") },
            { "f2", new UIKeyRepeater("f2", new(119*2, row1), keySize_small.Copy(), "f2", "F2") },
            { "f3", new UIKeyRepeater("f3", new(155*2, row1), keySize_small.Copy(), "f3", "F3") },
            { "f4", new UIKeyRepeater("f4", new(191*2, row1), keySize_small.Copy(), "f4", "F4") },
            { "f5", new UIKeyRepeater("f5", new(236*2, row1), keySize_small.Copy(), "f5", "F5") },
            { "f6", new UIKeyRepeater("f6", new(272*2, row1), keySize_small.Copy(), "f6", "F6") },
            { "f7", new UIKeyRepeater("f7", new(308*2, row1), keySize_small.Copy(), "f7", "F7") },
            { "f8", new UIKeyRepeater("f8", new(344*2, row1), keySize_small.Copy(), "f8", "F8") },
            { "f9", new UIKeyRepeater("f9", new(389*2, row1), keySize_small.Copy(), "f9", "F9") },
            { "f10", new UIKeyRepeater("f10", new(425*2, row1), keySize_small.Copy(), "f10", "F10") },
            { "f11", new UIKeyRepeater("f11", new(461*2, row1), keySize_small.Copy(), "f11", "F11") },
            { "f12", new UIKeyRepeater("f12", new(497*2, row1), keySize_small.Copy(), "f12", "F12") },
            { "print screen", new UIKeyRepeater("print screen", new(537*2, row1), keySize_small.Copy(), "\"print screen\"", "Psc") },
            { "scroll lock", new UIKeyRepeater("scroll lock", new(573*2, row1), keySize_small.Copy(), "\"scroll lock\"", "Slk") },
            { "pause", new UIKeyRepeater("pause", new(609*2, row1), keySize_small.Copy(), "pause", "Brk") },

            { "`", new UIKeyRepeater("`", new(11*2, row2), keySize_small.Copy(), "`", "`") },
            { "1", new UIKeyRepeater("1", new(47*2, row2), keySize_small.Copy(), "\"Number 1\"", "1") },
            { "2", new UIKeyRepeater("2", new(83*2, row2), keySize_small.Copy(), "\"Number 2\"", "2") },
            { "3", new UIKeyRepeater("3", new(119*2, row2), keySize_small.Copy(), "\"Number 3\"", "3") },
            { "4", new UIKeyRepeater("4", new(155*2, row2), keySize_small.Copy(), "\"Number 4\"", "4") },
            { "5", new UIKeyRepeater("5", new(191*2, row2), keySize_small.Copy(), "\"Number 5\"", "5") },
            { "6", new UIKeyRepeater("6", new(227*2, row2), keySize_small.Copy(), "\"Number 6\"", "6") },
            { "7", new UIKeyRepeater("7", new(263*2, row2), keySize_small.Copy(), "\"Number 7\"", "7") },
            { "8", new UIKeyRepeater("8", new(299*2, row2), keySize_small.Copy(), "\"Number 8\"", "8") },
            { "9", new UIKeyRepeater("9", new(335*2, row2), keySize_small.Copy(), "\"Number 9\"", "9") },
            { "0", new UIKeyRepeater("0", new(371*2, row2), keySize_small.Copy(), "\"Number 0\"", "0") },
            { "-", new UIKeyRepeater("-", new(407*2, row2), keySize_small.Copy(), "-", "-") },
            { "=", new UIKeyRepeater("=", new(443*2, row2), keySize_small.Copy(), "=", "=") },
            { "backspace", new UIKeyRepeater("backspace", new(479*2, row2), keySize_middle.Copy(), "backspace", "Backpack") },
            { "insert", new UIKeyRepeater("insert", new(537*2, row2), keySize_small.Copy(), "insert", "Ins") },
            { "home", new UIKeyRepeater("home", new(573*2, row2), keySize_small.Copy(), "home", "Home") },
            { "page up", new UIKeyRepeater("page up", new(609*2, row2), keySize_small.Copy(), "\"page up\"", "PgUp") },
            { "number lock", new UIKeyRepeater("num lock", new(649*2, row2), keySize_small.Copy(), "\"number lock\"", "Num") },
            { "numpad /", new UIKeyRepeater("numpad /", new(685*2, row2), keySize_small.Copy(), "\"numpad /\"", "/") },
            { "numpad *", new UIKeyRepeater("numpad *", new(721*2, row2), keySize_small.Copy(), "\"numpad *\"", "*") },
            { "numpad -", new UIKeyRepeater("numpad -", new(757*2, row2), keySize_small.Copy(), "\"numpad -\"", "-") },

            { "tab", new UIKeyRepeater("tab", new(11*2, row3), keySize_middle.Copy(), "tab", "Tab") },
            { "q", new UIKeyRepeater("q", new(65*2, row3), keySize_small.Copy(), "q", "Q") },
            { "w", new UIKeyRepeater("w", new(101*2, row3), keySize_small.Copy(), "w", "W") },
            { "e", new UIKeyRepeater("e", new(137*2, row3), keySize_small.Copy(), "e", "E") },
            { "r", new UIKeyRepeater("r", new(173*2, row3), keySize_small.Copy(), "r", "R") },
            { "t", new UIKeyRepeater("t", new(209*2, row3), keySize_small.Copy(), "t", "T") },
            { "y", new UIKeyRepeater("y", new(245*2, row3), keySize_small.Copy(), "y", "Y") },
            { "u", new UIKeyRepeater("u", new(281*2, row3), keySize_small.Copy(), "u", "U") },
            { "i", new UIKeyRepeater("i", new(317*2, row3), keySize_small.Copy(), "i", "I") },
            { "o", new UIKeyRepeater("o", new(353*2, row3), keySize_small.Copy(), "o", "O") },
            { "p", new UIKeyRepeater("p", new(389*2, row3), keySize_small.Copy(), "p", "P") },
            { "[", new UIKeyRepeater("[", new(425*2, row3), keySize_small.Copy(), "[", "[") },
            { "]", new UIKeyRepeater("]", new(461*2, row3), keySize_small.Copy(), "]", "]") },
            { "\\", new UIKeyRepeater("\\", new(497*2, row3), keySize_small.Copy(), "\\", "\\") },
            { "delete", new UIKeyRepeater("delete", new(537*2, row3), keySize_small.Copy(), "delete", "Del") },
            { "end", new UIKeyRepeater("end", new(573*2, row3), keySize_small.Copy(), "end", "End") },
            { "page down", new UIKeyRepeater("page down", new(609*2, row3), keySize_small.Copy(), "\"page down\"", "PgDn") },
            { "numpad 7", new UIKeyRepeater("numpad 7", new(649*2, row3), keySize_small.Copy(), "\"numpad 7\"", "7") },
            { "numpad 8", new UIKeyRepeater("numpad 8", new(685*2, row3), keySize_small.Copy(), "\"numpad 8\"", "8") },
            { "numpad 9", new UIKeyRepeater("numpad 9", new(721*2, row3), keySize_small.Copy(), "\"numpad 9\"", "9") },
            { "numpad +", new UIKeyRepeater("numpad +", new(757*2, row3), keySize_large_T.Copy(), "\"numpad +\"", "+") },
            
            { "caps lock", new UIKeyRepeater("caps lock", new(11*2, row4), keySize_large.Copy(), "\"caps lock\"", "Caps") },
            { "a", new UIKeyRepeater("a", new(83*2, row4), keySize_small.Copy(), "a", "A") },
            { "s", new UIKeyRepeater("s", new(119*2, row4), keySize_small.Copy(), "s", "S") },
            { "d", new UIKeyRepeater("d", new(155*2, row4), keySize_small.Copy(), "d", "D") },
            { "f", new UIKeyRepeater("f", new(191*2, row4), keySize_small.Copy(), "f", "F") },
            { "g", new UIKeyRepeater("g", new(227*2, row4), keySize_small.Copy(), "g", "G") },
            { "h", new UIKeyRepeater("h", new(263*2, row4), keySize_small.Copy(), "h", "H") },
            { "j", new UIKeyRepeater("j", new(299*2, row4), keySize_small.Copy(), "j", "J") },
            { "k", new UIKeyRepeater("k", new(335*2, row4), keySize_small.Copy(), "k", "K") },
            { "l", new UIKeyRepeater("l", new(371*2, row4), keySize_small.Copy(), "l", "L") },
            { ";", new UIKeyRepeater(";", new(407*2, row4), keySize_small.Copy(), ";", ";") },
            { "'", new UIKeyRepeater("'", new(443*2, row4), keySize_small.Copy(), "'", "'") },
            { "enter", new UIKeyRepeater("enter", new(479*2, row4), keySize_middle.Copy(), "enter", "Enter") },
            { "numpad 4", new UIKeyRepeater("numpad 4", new(649*2, row4), keySize_small.Copy(), "\"numpad 4\"", "4") },
            { "numpad 5", new UIKeyRepeater("numpad 5", new(685*2, row4), keySize_small.Copy(), "\"numpad 5\"", "5") },
            { "numpad 6", new UIKeyRepeater("numpad 6", new(721*2, row4), keySize_small.Copy(), "\"numpad 6\"", "6") },

            { "left shift", new UIKeyRepeater("left shift", new(11*2, row5), keySize_huge.Copy(), "\"left shift\"", "Shift") },
            { "z", new UIKeyRepeater("z", new(101*2, row5), keySize_small.Copy(), "z", "Z") },
            { "x", new UIKeyRepeater("x", new(137*2, row5), keySize_small.Copy(), "x", "X") },
            { "c", new UIKeyRepeater("c", new(173*2, row5), keySize_small.Copy(), "c", "C") },
            { "v", new UIKeyRepeater("v", new(209*2, row5), keySize_small.Copy(), "v", "V") },
            { "b", new UIKeyRepeater("b", new(245*2, row5), keySize_small.Copy(), "b", "B") },
            { "n", new UIKeyRepeater("n", new(281*2, row5), keySize_small.Copy(), "n", "N") },
            { "m", new UIKeyRepeater("m", new(317*2, row5), keySize_small.Copy(), "m", "M") },
            { ",", new UIKeyRepeater(",", new(353*2, row5), keySize_small.Copy(), ",", ",") },
            { ".", new UIKeyRepeater(".", new(389*2, row5), keySize_small.Copy(), ".", ".") },
            { "/", new UIKeyRepeater("/", new(425*2, row5), keySize_small.Copy(), "/", "/") },
            { "right shift", new UIKeyRepeater("right shift", new(461*2, row5), keySize_large.Copy(), "\"right shift\"", "Shift") },
            { "up", new UIKeyRepeater("up", new(573*2, row5), keySize_small.Copy(), "up", "Up") },
            { "numpad 1", new UIKeyRepeater("numpad 1", new(649*2, row5), keySize_small.Copy(), "numpad 1", "1") },
            { "numpad 2", new UIKeyRepeater("numpad 2", new(685*2, row5), keySize_small.Copy(), "numpad 2", "2") },
            { "numpad 3", new UIKeyRepeater("numpad 3", new(721*2, row5), keySize_small.Copy(), "numpad 3", "3") },
            { "numpad enter", new UIKeyRepeater("numpad enter", new(757*2, row5), keySize_large_T.Copy(), "enter", "Enter") },

            { "left ctrl", new UIKeyRepeater("left ctrl", new(11*2, row6), keySize_middle.Copy(), "\"left ctrl\"", "Ctrl") },
            { "windows", new UIKeyRepeater("windows", new(65*2, row6), keySize_middle.Copy(), "windows", "Win") },
            { "left alt", new UIKeyRepeater("left alt", new(119*2, row6), keySize_middle.Copy(), "\"left alt\"", "Alt") },
            { "space", new UIKeyRepeater("space", new(173*2, row6), keySize_veryHuge.Copy(), "space", "Space") },
            { "right alt", new UIKeyRepeater("right alt", new(371*2, row6), keySize_middle.Copy(), "\"right alt\"", "Alt") },
            { "menu", new UIKeyRepeater("menu", new(425*2, row6), keySize_middle.Copy(), "menu", "Menu") },
            { "right ctrl", new UIKeyRepeater("right ctrl", new(479*2, row6), keySize_middle.Copy(), "\"right ctrl\"", "Ctrl") },
            { "left", new UIKeyRepeater("left", new(537*2, row6), keySize_small.Copy(), "left", "Left") },
            { "down", new UIKeyRepeater("down", new(573*2, row6), keySize_small.Copy(), "down", "Down") },
            { "right", new UIKeyRepeater("right", new(609*2, row6), keySize_small.Copy(), "right", "Right") },
            { "numpad 0", new UIKeyRepeater("numpad 0", new(649*2, row6), keySize_large.Copy(), "\"numpad 0\"", "0") },
            { "numpad .", new UIKeyRepeater("numpad .", new(721*2, row6), keySize_small.Copy(), "\"numpad .\"", ".") },
        };

        List<UIInfo> subUIs = new(){
            new() { type = "UICloseButtom", sizeDelta = new(16*2, 16*2), anchoredPosition = new(-7*2, -7*2)},
            new() { type = "UIResizeButtom", background_key="", sizeDelta = new(16*2, 16*2), anchoredPosition = new(-7*2, 7*2)},
        };



        foreach (UIKeyRepeater keyInfo in keys_infos.Values){
            UIInfo info = UIClass._UIInfos["UIKey"].Copy();
            info.name = keyInfo.name;
            info.anchoredPosition = keyInfo.pos;
            info.sizeDelta = keyInfo.size;
            info.attributes = new() { { "COMMAND", $"FROM_INPUT --key {keyInfo.cmdName}" }, };
            info.subUIs = new(){
                new UIScrollTextInfo(){ type = "UIKeyName", text = keyInfo.shortName, },
                new UIScrollTextInfo(){ type = "UIKeyDescription", text = "占位符", },
            };
            UIClass._add($"UIKey_{info.name}", info);
            subUIs.Add(UIClass._UIInfos[$"UIKey_{info.name}"]);
        }


        UIClass._add("UIKeyboardShortcut", new (){
            type = "UIKeyboardShortcut",
            background_key = "ui_5", 
            // background_key = "ui_TitleBg",
            PixelsPerUnitMultiplier = 1f,
            sizeDelta = new (800*2, 288*2),
            interactions = new List<string>() {
                "UIDrag",
            },
            // rightMenu_name = "UIRightMenuInteractionManager_KeyboardShortcut",
            subUIs = subUIs,
            // subUIs = new(){
            //     new() { type = "UICloseButtom", sizeDelta = new(16*2, 16*2), anchoredPosition = new(-7*2, -7*2)},
            //     new() { type = "UIResizeButtom", background_key="", sizeDelta = new(16*2, 16*2), anchoredPosition = new(-7*2, 7*2)},

            //     // new() { type = "UIKey_escape"},
            //     // new() { type = "UIKey_f1"},
            //     // new() { type = "UIKey_f2"},
            //     // new() { type = "UIKey_f3"},
            //     // new() { type = "UIKey_f4"},
            //     // new() { type = "UIKey_f5"},
            //     // new() { type = "UIKey_f6"},
            //     // new() { type = "UIKey_f7"},
            //     // new() { type = "UIKey_f8"},
            //     // new() { type = "UIKey_f9"},

            //     new() { type = "UIKeyShortcut", name="key_escape", anchoredPosition = new(11*2, -36*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key escape" },}, },
            //     new() { type = "UIKeyShortcut", name="key_f1", anchoredPosition = new(83*2, -36*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key f1" },}, },
            //     new() { type = "UIKeyShortcut", name="key_f2", anchoredPosition = new(119*2, -36*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key f2" },}, },
            //     new() { type = "UIKeyShortcut", name="key_f3", anchoredPosition = new(155*2, -36*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key f3" },}, },
            //     new() { type = "UIKeyShortcut", name="key_f4", anchoredPosition = new(191*2, -36*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key f4" },}, },
            //     new() { type = "UIKeyShortcut", name="key_f5", anchoredPosition = new(236*2, -36*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key f5" },}, },
            //     new() { type = "UIKeyShortcut", name="key_f6", anchoredPosition = new(272*2, -36*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key f6" },}, },
            //     new() { type = "UIKeyShortcut", name="key_f7", anchoredPosition = new(308*2, -36*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key f7" },}, },
            //     new() { type = "UIKeyShortcut", name="key_f8", anchoredPosition = new(344*2, -36*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key f8" },}, },
            //     new() { type = "UIKeyShortcut", name="key_f9", anchoredPosition = new(389*2, -36*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key f9" },}, },
            //     new() { type = "UIKeyShortcut", name="key_f10", anchoredPosition = new(425*2, -36*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key f10" },}, },
            //     new() { type = "UIKeyShortcut", name="key_f11", anchoredPosition = new(461*2, -36*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key f11" },}, },
            //     new() { type = "UIKeyShortcut", name="key_f12", anchoredPosition = new(497*2, -36*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key f12" },}, },
            //     new() { type = "UIKeyShortcut", name="key_print screen", anchoredPosition = new(537*2, -36*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key \"print screen\"" },}, },
            //     new() { type = "UIKeyShortcut", name="key_scroll lock", anchoredPosition = new(573*2, -36*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key \"scroll lock\"" },}, },
            //     new() { type = "UIKeyShortcut", name="key_pause", anchoredPosition = new(609*2, -36*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key pause" },}, },

            //     new() { type = "UIKeyShortcut", name="key_`", anchoredPosition = new(11*2, -76*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key `" },}, },
            //     new() { type = "UIKeyShortcut", name="key_1", anchoredPosition = new(47*2, -76*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key \"number 0\"" },}, },
            //     new() { type = "UIKeyShortcut", name="key_2", anchoredPosition = new(83*2, -76*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key \"number 0\"" },}, },
            //     new() { type = "UIKeyShortcut", name="key_3", anchoredPosition = new(119*2, -76*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key \"number 0\"" },}, },
            //     new() { type = "UIKeyShortcut", name="key_4", anchoredPosition = new(155*2, -76*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key \"number 0\"" },}, },
            //     new() { type = "UIKeyShortcut", name="key_5", anchoredPosition = new(191*2, -76*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key \"number 0\"" },}, },
            //     new() { type = "UIKeyShortcut", name="key_6", anchoredPosition = new(227*2, -76*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key \"number 0\"" },}, },
            //     new() { type = "UIKeyShortcut", name="key_7", anchoredPosition = new(263*2, -76*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key \"number 0\"" },}, },
            //     new() { type = "UIKeyShortcut", name="key_8", anchoredPosition = new(299*2, -76*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key \"number 0\"" },}, },
            //     new() { type = "UIKeyShortcut", name="key_9", anchoredPosition = new(335*2, -76*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key \"number 0\"" },}, },
            //     new() { type = "UIKeyShortcut", name="key_0", anchoredPosition = new(371*2, -76*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key \"number 0\"" },}, },
            //     new() { type = "UIKeyShortcut", name="key_-", anchoredPosition = new(407*2, -76*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key -" },}, },
            //     new() { type = "UIKeyShortcut", name="key_=", anchoredPosition = new(443*2, -76*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key =" },}, },
            //     new() { type = "UIKeyShortcut", name="key_backspace", sizeDelta = new(50*2, 32*2), anchoredPosition = new(479*2, -76*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key backspace" },}, },
            //     new() { type = "UIKeyShortcut", name="key_insert", anchoredPosition = new(537*2, -76*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key insert" },}, },
            //     new() { type = "UIKeyShortcut", name="key_home", anchoredPosition = new(573*2, -76*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key home" },}, },
            //     new() { type = "UIKeyShortcut", name="key_page up", anchoredPosition = new(609*2, -76*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key \"page up\"" },}, },
            //     new() { type = "UIKeyShortcut", name="key_number lock", anchoredPosition = new(649*2, -76*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key \"number lock\"" },}, },
            //     new() { type = "UIKeyShortcut", name="key_numpad /", anchoredPosition = new(685*2, -76*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key \"numpad /\"" },}, },
            //     new() { type = "UIKeyShortcut", name="key_numpad *", anchoredPosition = new(721*2, -76*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key \"numpad *\"" },}, },
            //     new() { type = "UIKeyShortcut", name="key_numpad -", anchoredPosition = new(757*2, -76*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key \"numpad -\"" },}, },

            //     new() { type = "UIKeyShortcut", name="key_tab", sizeDelta = new(50*2, 32*2), anchoredPosition = new(11*2, -112*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key tab" },}, },
            //     new() { type = "UIKeyShortcut", name="key_q", anchoredPosition = new(65*2, -112*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key q" },}, },
            //     new() { type = "UIKeyShortcut", name="key_w", anchoredPosition = new(101*2, -112*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key w" },}, },
            //     new() { type = "UIKeyShortcut", name="key_e", anchoredPosition = new(137*2, -112*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key e" },}, },
            //     new() { type = "UIKeyShortcut", name="key_r", anchoredPosition = new(173*2, -112*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key r" },}, },
            //     new() { type = "UIKeyShortcut", name="key_t", anchoredPosition = new(209*2, -112*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key t" },}, },
            //     new() { type = "UIKeyShortcut", name="key_y", anchoredPosition = new(245*2, -112*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key y" },}, },
            //     new() { type = "UIKeyShortcut", name="key_u", anchoredPosition = new(281*2, -112*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key u" },}, },
            //     new() { type = "UIKeyShortcut", name="key_i", anchoredPosition = new(317*2, -112*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key i" },}, },
            //     new() { type = "UIKeyShortcut", name="key_o", anchoredPosition = new(353*2, -112*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key o" },}, },
            //     new() { type = "UIKeyShortcut", name="key_p", anchoredPosition = new(389*2, -112*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key p" },}, },
            //     new() { type = "UIKeyShortcut", name="key_[", anchoredPosition = new(425*2, -112*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key []" },}, },
            //     new() { type = "UIKeyShortcut", name="key_]", anchoredPosition = new(461*2, -112*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key ]" },}, },
            //     new() { type = "UIKeyShortcut", name="key_\\", anchoredPosition = new(497*2, -112*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key \\" },}, },
            //     new() { type = "UIKeyShortcut", name="key_delete", anchoredPosition = new(537*2, -112*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key delete" },}, },
            //     new() { type = "UIKeyShortcut", name="key_end", anchoredPosition = new(573*2, -112*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key end" },}, },
            //     new() { type = "UIKeyShortcut", name="key_page down", anchoredPosition = new(609*2, -112*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key \"page down\"" },}, },
            //     new() { type = "UIKeyShortcut", name="key_numpad 7", anchoredPosition = new(649*2, -112*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key \"numpad 7\"" },}, },
            //     new() { type = "UIKeyShortcut", name="key_numpad 8", anchoredPosition = new(685*2, -112*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key \"numpad 8\"" },}, },
            //     new() { type = "UIKeyShortcut", name="key_numpad 9", anchoredPosition = new(721*2, -112*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key \"numpad 9\"" },}, },
            //     new() { type = "UIKeyShortcut", name="key_numpad +", sizeDelta = new(32*2, 68*2), anchoredPosition = new(757*2, -112*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key \"numpad +\"" },}, },

            //     new() { type = "UIKeyShortcut", name="key_caps lock", sizeDelta = new(68*2, 32*2), anchoredPosition = new(11*2, -148*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key \"caps lock\"" },}, },
            //     new() { type = "UIKeyShortcut", name="key_a", anchoredPosition = new(83*2, -148*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key a" },}, },
            //     new() { type = "UIKeyShortcut", name="key_s", anchoredPosition = new(119*2, -148*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key s" },}, },
            //     new() { type = "UIKeyShortcut", name="key_d", anchoredPosition = new(155*2, -148*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key d" },}, },
            //     new() { type = "UIKeyShortcut", name="key_f", anchoredPosition = new(191*2, -148*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key f" },}, },
            //     new() { type = "UIKeyShortcut", name="key_g", anchoredPosition = new(227*2, -148*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key g" },}, },
            //     new() { type = "UIKeyShortcut", name="key_h", anchoredPosition = new(263*2, -148*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key h" },}, },
            //     new() { type = "UIKeyShortcut", name="key_j", anchoredPosition = new(299*2, -148*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key j" },}, },
            //     new() { type = "UIKeyShortcut", name="key_k", anchoredPosition = new(335*2, -148*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key k" },}, },
            //     new() { type = "UIKeyShortcut", name="key_l", anchoredPosition = new(371*2, -148*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key l" },}, },
            //     new() { type = "UIKeyShortcut", name="key_;", anchoredPosition = new(407*2, -148*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key ;" },}, },
            //     new() { type = "UIKeyShortcut", name="key_'", anchoredPosition = new(443*2, -148*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key '" },}, },
            //     new() { type = "UIKeyShortcut", name="key_enter", sizeDelta = new(50*2, 32*2), anchoredPosition = new(479*2, -148*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key enter" },}, },
            //     new() { type = "UIKeyShortcut", name="key_numpad 4", anchoredPosition = new(649*2, -148*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key \"numpad 4\"" },}, },
            //     new() { type = "UIKeyShortcut", name="key_numpad 5", anchoredPosition = new(685*2, -148*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key \"numpad 5\"" },}, },
            //     new() { type = "UIKeyShortcut", name="key_numpad 6", anchoredPosition = new(721*2, -148*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key \"numpad 6\"" },}, },

            //     new() { type = "UIKeyShortcut", name="key_left shift", sizeDelta = new(86*2, 32*2), anchoredPosition = new(11*2, -184*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key \"left shift\"" },}, },
            //     new() { type = "UIKeyShortcut", name="key_z", anchoredPosition = new(101*2, -184*2), 
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key z" },}, },
            //     new() { type = "UIKeyShortcut", name="key_x", anchoredPosition = new(137*2, -184*2),                    
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key x" },}, },
            //     new() { type = "UIKeyShortcut", name="key_c", anchoredPosition = new(173*2, -184*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key c" },}, },
            //     new() { type = "UIKeyShortcut", name="key_v", anchoredPosition = new(209*2, -184*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key v" },}, },
            //     new() { type = "UIKeyShortcut", name="key_b", anchoredPosition = new(245*2, -184*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key b" },}, },
            //     new() { type = "UIKeyShortcut", name="key_n", anchoredPosition = new(281*2, -184*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key n" },}, },
            //     new() { type = "UIKeyShortcut", name="key_m", anchoredPosition = new(317*2, -184*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key m" },}, },
            //     new() { type = "UIKeyShortcut", name="key_,", anchoredPosition = new(353*2, -184*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key ," },}, },
            //     new() { type = "UIKeyShortcut", name="key_.", anchoredPosition = new(389*2, -184*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key ." },}, },
            //     new() { type = "UIKeyShortcut", name="key_/", anchoredPosition = new(425*2, -184*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key /" },}, },
            //     new() { type = "UIKeyShortcut", name="key_right shift", sizeDelta = new(68*2, 32*2), anchoredPosition = new(461*2, -184*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key \"right shift\"" },}, },
            //     new() { type = "UIKeyShortcut", name="key_up", anchoredPosition = new(573*2, -184*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key up" },}, },
            //     new() { type = "UIKeyShortcut", name="key_numpad 1", anchoredPosition = new(649*2, -184*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key \"numpad 1\"" },}, },
            //     new() { type = "UIKeyShortcut", name="key_numpad 2", anchoredPosition = new(685*2, -184*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key \"numpad 2\"" },}, },
            //     new() { type = "UIKeyShortcut", name="key_numpad 3", anchoredPosition = new(721*2, -184*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key \"numpad 3\"" },}, },
            //     new() { type = "UIKeyShortcut", name="key_numpad enter", sizeDelta = new(32*2, 68*2), anchoredPosition = new(757*2, -184*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key enter" },}, },

            //     new() { type = "UIKeyShortcut", name="key_left ctrl", sizeDelta = new(50*2, 32*2), anchoredPosition = new(11*2, -220*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key \"left ctrl\"" },}, },
            //     new() { type = "UIKeyShortcut", name="key_windows", sizeDelta = new(50*2, 32*2), anchoredPosition = new(65*2, -220*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key windows" },}, },
            //     new() { type = "UIKeyShortcut", name="key_left alt", sizeDelta = new(50*2, 32*2), anchoredPosition = new(119*2, -220*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key \"left alt\"" },}, },
            //     new() { type = "UIKeyShortcut", name="key_space", sizeDelta = new(194*2, 32*2), anchoredPosition = new(173*2, -220*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key space" },}, },
            //     new() { type = "UIKeyShortcut", name="key_right alt", sizeDelta = new(50*2, 32*2), anchoredPosition = new(371*2, -220*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key \"right alt\"" },}, },
            //     new() { type = "UIKeyShortcut", name="key_menu", sizeDelta = new(50*2, 32*2), anchoredPosition = new(425*2, -220*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key \"menu\"" },}, },
            //     new() { type = "UIKeyShortcut", name="key_right ctrl", sizeDelta = new(50*2, 32*2), anchoredPosition = new(479*2, -220*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key \"right ctrl\"" },}, },
            //     new() { type = "UIKeyShortcut", name="key_left", anchoredPosition = new(537*2, -220*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key left" },}, },
            //     new() { type = "UIKeyShortcut", name="key_down", anchoredPosition = new(573*2, -220*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key down" },}, },
            //     new() { type = "UIKeyShortcut", name="key_right", anchoredPosition = new(609*2, -220*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key right" },}, },
            //     new() { type = "UIKeyShortcut", name="key_numpad 0", sizeDelta = new(68*2, 32*2), anchoredPosition = new(649*2, -220*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key \"numpad 0\"" },}, },
            //     new() { type = "UIKeyShortcut", name="key_numpad .", anchoredPosition = new(721*2, -220*2),
            //         attributes = new() {{"COMMAND", "FROM_INPUT --key \"numpad .\"" },}, },


            // },
        });

    }
}