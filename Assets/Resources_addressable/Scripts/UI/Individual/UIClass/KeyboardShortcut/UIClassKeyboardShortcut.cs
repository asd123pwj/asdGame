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
        
        

        UIClass._add("UIRightMenuInteractionManager_UIKey", new UIScrollViewInfo(){
            class_type = "UIRightMenuInteractionManager_UIKey",
            base_type = "UIRightMenu",
            background_key = "ui_RoundedIcon_32",
            PixelsPerUnitMultiplier = 1,
            prefab_key = "UIScrollView",
            // sizeDelta = new (96*1 + 16 + 16, 32*3 + 4*2 + 16 + 16),
            // padding = new RectOffset(16, 16, 16, 16),
            paddingLeft = 16, paddingRight = 16, paddingTop = 16, paddingBottom = 16,
            spacing = new (8, 8),
            // cellSize = new (96, 32),
            maxSize = new (300, 300),
            rightMenu_name = "UIRightMenuInteractionManager_UIKey",
            // constraintCount = 1,
            anchoredPosition = new (8, -8),
            interactions = new List<string>() {
                nameof(UIDrag),
                // "UIDeselectClose"
                nameof(UIOpenRightMenu),
            },
            items = new(){
                // new() {
                //     type = "UIExecuteCommandFromMessage", sizeDelta = new (196, 32), messageID = "UIExecuteCommand"
                // },
                // new UIInputFieldInfo() {
                //     type = "UIInputField", sizeDelta = new (96, 32), messageID = "UIExecuteCommand"
                // },
                // new() {
                //     type = "UIHighlight_a0.5_ScrollPass2Parent", sizeDelta = new (96, 62),
                // },
                // new() {
                //     type = "UIHighlight_a0.5_ScrollPass2Parent", sizeDelta = new (96, 32),
                // },
                new UIScrollTextInfo() {
                    class_type = "UIOpenAttributeManager", minSize = new (196, 32), maxSize = new (196, 32),
                },
            },
            subUIs = new()
        });


        // UIClass._add("UIOpenAttributeManager", new (){
        //     type="UIOpenAttributeManager",
        //     background_key="p5", 
        //     interactions = new List<string>() {
        //         "UIOpenAttributeManager",
        //         "UIPassScroll2Parent"
        //     },
        // });

        UIClass._add("UIExecuteCommandFromMessage", new (){
            class_type="UIExecuteCommandFromMessage",
            background_key="p5", 
            interactions = new List<string>() {
                // "UISetTop",
                nameof(UIExecuteCommandFromMessage),
                nameof(UIPassScroll2Parent)
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
            class_type="UIKey", background_key="ui_RoundedIcon_16", PixelsPerUnitMultiplier=1,
            rightMenu_name = "UIRightMenuInteractionManager_UIKey",
            interactions = new () {
                nameof(UIOpenRightMenu), 
                nameof(UIExecuteCommandFromAttribute),
                nameof(UIPassBeginDrag2Parent), 
                nameof(UIPassEndDrag2Parent),
                nameof(UIPassDrag2Parent),
                nameof(UIPassPointerDown2Parent),
            },
            subUIs = new(){
                new UIScrollTextInfo(){ class_type = "UIKeyName", text = "Esc", },
                new UIScrollTextInfo(){ class_type = "UIKeyDescription", text = "占位符", },
            }
        });

        UIClass._add("UIKeyName", new UIScrollTextInfo(){
            class_type = "UIKeyName", base_type = "UIScrollText",
            fontSize = 16, marginTop=0, marginBottom=0, marginLeft=4, marginRight=0, 
            minSize = new(24, 24), maxSize = new(128, 24), anchoredPosition= new(6, -8), 
            prefab_key = "UIScrollText", background_key = "",
            interactions = new() {
                nameof(UIPassBeginDrag2Parent), 
                nameof(UIPassEndDrag2Parent),
                nameof(UIPassDrag2Parent),
                nameof(UIPassPointerDown2Parent),
            }
        });
        
        UIClass._add("UIKeyDescription", new UIScrollTextInfo(){
            class_type = "UIKeyDescription", base_type = "UIScrollText",
            fontSize = 16, marginTop=0, marginBottom=0, marginLeft=4, marginRight=0, 
            minSize = new(32, 24), maxSize = new(60, 24), anchoredPosition= new(6, -32), 
            prefab_key = "UIScrollText", background_key = "",
            interactions = new() {
                nameof(UIPassBeginDrag2Parent), 
                nameof(UIPassEndDrag2Parent),
                nameof(UIPassDrag2Parent),
                nameof(UIPassPointerDown2Parent),
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
            { "print screen", new UIKeyRepeater("print screen", new(537*2, row1), keySize_small.Copy(), "print screen", "Psc") },
            { "scroll lock", new UIKeyRepeater("scroll lock", new(573*2, row1), keySize_small.Copy(), "scroll lock", "Slk") },
            { "pause", new UIKeyRepeater("pause", new(609*2, row1), keySize_small.Copy(), "pause", "Brk") },

            { "`", new UIKeyRepeater("`", new(11*2, row2), keySize_small.Copy(), "`", "`") },
            { "1", new UIKeyRepeater("1", new(47*2, row2), keySize_small.Copy(), "Number 1", "1") },
            { "2", new UIKeyRepeater("2", new(83*2, row2), keySize_small.Copy(), "Number 2", "2") },
            { "3", new UIKeyRepeater("3", new(119*2, row2), keySize_small.Copy(), "Number 3", "3") },
            { "4", new UIKeyRepeater("4", new(155*2, row2), keySize_small.Copy(), "Number 4", "4") },
            { "5", new UIKeyRepeater("5", new(191*2, row2), keySize_small.Copy(), "Number 5", "5") },
            { "6", new UIKeyRepeater("6", new(227*2, row2), keySize_small.Copy(), "Number 6", "6") },
            { "7", new UIKeyRepeater("7", new(263*2, row2), keySize_small.Copy(), "Number 7", "7") },
            { "8", new UIKeyRepeater("8", new(299*2, row2), keySize_small.Copy(), "Number 8", "8") },
            { "9", new UIKeyRepeater("9", new(335*2, row2), keySize_small.Copy(), "Number 9", "9") },
            { "0", new UIKeyRepeater("0", new(371*2, row2), keySize_small.Copy(), "Number 0", "0") },
            { "-", new UIKeyRepeater("-", new(407*2, row2), keySize_small.Copy(), "-", "-") },
            { "=", new UIKeyRepeater("=", new(443*2, row2), keySize_small.Copy(), "=", "=") },
            { "backspace", new UIKeyRepeater("backspace", new(479*2, row2), keySize_middle.Copy(), "backspace", "Backpack") },
            { "insert", new UIKeyRepeater("insert", new(537*2, row2), keySize_small.Copy(), "insert", "Ins") },
            { "home", new UIKeyRepeater("home", new(573*2, row2), keySize_small.Copy(), "home", "Home") },
            { "page up", new UIKeyRepeater("page up", new(609*2, row2), keySize_small.Copy(), "page up", "PgUp") },
            { "number lock", new UIKeyRepeater("num lock", new(649*2, row2), keySize_small.Copy(), "number lock", "Num") },
            { "numpad /", new UIKeyRepeater("numpad /", new(685*2, row2), keySize_small.Copy(), "numpad /", "/") },
            { "numpad *", new UIKeyRepeater("numpad *", new(721*2, row2), keySize_small.Copy(), "numpad *", "*") },
            { "numpad -", new UIKeyRepeater("numpad -", new(757*2, row2), keySize_small.Copy(), "numpad -", "-") },

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
            { "page down", new UIKeyRepeater("page down", new(609*2, row3), keySize_small.Copy(), "page down", "PgDn") },
            { "numpad 7", new UIKeyRepeater("numpad 7", new(649*2, row3), keySize_small.Copy(), "numpad 7", "7") },
            { "numpad 8", new UIKeyRepeater("numpad 8", new(685*2, row3), keySize_small.Copy(), "numpad 8", "8") },
            { "numpad 9", new UIKeyRepeater("numpad 9", new(721*2, row3), keySize_small.Copy(), "numpad 9", "9") },
            { "numpad +", new UIKeyRepeater("numpad +", new(757*2, row3), keySize_large_T.Copy(), "numpad +", "+") },
            
            { "caps lock", new UIKeyRepeater("caps lock", new(11*2, row4), keySize_large.Copy(), "caps lock", "Caps") },
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
            { "numpad 4", new UIKeyRepeater("numpad 4", new(649*2, row4), keySize_small.Copy(), "numpad 4", "4") },
            { "numpad 5", new UIKeyRepeater("numpad 5", new(685*2, row4), keySize_small.Copy(), "numpad 5", "5") },
            { "numpad 6", new UIKeyRepeater("numpad 6", new(721*2, row4), keySize_small.Copy(), "numpad 6", "6") },

            { "left shift", new UIKeyRepeater("left shift", new(11*2, row5), keySize_huge.Copy(), "left shift", "Shift") },
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
            { "right shift", new UIKeyRepeater("right shift", new(461*2, row5), keySize_large.Copy(), "right shift", "Shift") },
            { "up", new UIKeyRepeater("up", new(573*2, row5), keySize_small.Copy(), "up", "Up") },
            { "numpad 1", new UIKeyRepeater("numpad 1", new(649*2, row5), keySize_small.Copy(), "numpad 1", "1") },
            { "numpad 2", new UIKeyRepeater("numpad 2", new(685*2, row5), keySize_small.Copy(), "numpad 2", "2") },
            { "numpad 3", new UIKeyRepeater("numpad 3", new(721*2, row5), keySize_small.Copy(), "numpad 3", "3") },
            { "numpad enter", new UIKeyRepeater("numpad enter", new(757*2, row5), keySize_large_T.Copy(), "enter", "Enter") },

            { "left ctrl", new UIKeyRepeater("left ctrl", new(11*2, row6), keySize_middle.Copy(), "left ctrl", "Ctrl") },
            { "windows", new UIKeyRepeater("windows", new(65*2, row6), keySize_middle.Copy(), "windows", "Win") },
            { "left alt", new UIKeyRepeater("left alt", new(119*2, row6), keySize_middle.Copy(), "left alt", "Alt") },
            { "space", new UIKeyRepeater("space", new(173*2, row6), keySize_veryHuge.Copy(), "space", "Space") },
            { "right alt", new UIKeyRepeater("right alt", new(371*2, row6), keySize_middle.Copy(), "right alt", "Alt") },
            { "menu", new UIKeyRepeater("menu", new(425*2, row6), keySize_middle.Copy(), "menu", "Menu") },
            { "right ctrl", new UIKeyRepeater("right ctrl", new(479*2, row6), keySize_middle.Copy(), "right ctrl", "Ctrl") },
            { "left", new UIKeyRepeater("left", new(537*2, row6), keySize_small.Copy(), "left", "Left") },
            { "down", new UIKeyRepeater("down", new(573*2, row6), keySize_small.Copy(), "down", "Down") },
            { "right", new UIKeyRepeater("right", new(609*2, row6), keySize_small.Copy(), "right", "Right") },
            { "numpad 0", new UIKeyRepeater("numpad 0", new(649*2, row6), keySize_large.Copy(), "numpad 0", "0") },
            { "numpad .", new UIKeyRepeater("numpad .", new(721*2, row6), keySize_small.Copy(), "numpad .", ".") },
        };

        List<UIInfo> subUIs = new(){
            new() { class_type = "UICloseButtom", sizeDelta = new(16*2, 16*2), anchoredPosition = new(-7*2, -7*2)},
            new() { class_type = "UIResizeButtom", background_key="", sizeDelta = new(16*2, 16*2), anchoredPosition = new(-7*2, 7*2)},
        };



        foreach (UIKeyRepeater keyInfo in keys_infos.Values){
            UIInfo info = UIClass._UIInfos["UIKey"].Copy();
            info.name = keyInfo.name;
            info.anchoredPosition = keyInfo.pos;
            info.sizeDelta = keyInfo.size;
            info.attributes = new() { { "COMMAND", $"FROM_INPUT --key \"{keyInfo.cmdName}\"" }, };
            info.subUIs = new(){
                new UIScrollTextInfo(){ class_type = "UIKeyName", text = keyInfo.shortName, },
                new UIScrollTextInfo(){ class_type = "UIKeyDescription", text = "占位符", },
            };
            UIClass._add($"UIKey_{info.name}", info);
            subUIs.Add(UIClass._UIInfos[$"UIKey_{info.name}"]);
        }


        UIClass._add("UIKeyboardShortcut", new (){
            class_type = "UIKeyboardShortcut",
            background_key = "ui_5", 
            // background_key = "ui_TitleBg",
            PixelsPerUnitMultiplier = 1f,
            sizeDelta = new (800*2, 288*2),
            interactions = new List<string>() {
                nameof(UIDrag),
            },
            // rightMenu_name = "UIRightMenuInteractionManager_KeyboardShortcut",
            subUIs = subUIs,
        });

    }
}