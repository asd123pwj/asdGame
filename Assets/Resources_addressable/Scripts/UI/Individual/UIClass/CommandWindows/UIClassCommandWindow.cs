using System.Collections.Generic;

public class UIClassCommandWindow{
    public UIClassCommandWindow(){
        UIClass._add("UICommandWindow", new(){
            type = "UICommandWindow",
            background_key = "ui_1", sizeDelta = new(800, 400),
            interactions = new List<string>() {
                // "UISetTop",
                "UIDrag",
            },
            subUIs = new(){
                new() { type = "UICloseButtom", sizeDelta = new(25, 25)},
                new() { type = "UIResizeButtom", sizeDelta = new(25, 25)},
                new UIInputFieldInfo() { type = "UIInputField", sizeDelta = new(800-25-2*2, 25-2*2),
                        pivot = new(0, 0), anchorMin = new(0, 0), anchorMax = new(0, 0),
                        anchoredPosition = new(2, 2), PixelsPerUnitMultiplier=4,
                        messageID = "SYSTEM_COMMAND",
                },
                new UIScrollTextInfo() { type = "UIScrollText", 
                    // sizeDelta = new(800-25, 400-25*2-12.5f*2), 
                    anchoredPosition = new(12.5f, -(25+12.5f)),
                    messageID = "SYSTEM_COMMAND", background_key = "p5_a0.5",
                },
            },
        });

    }
}