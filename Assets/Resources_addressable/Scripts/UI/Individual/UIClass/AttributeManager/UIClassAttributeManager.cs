using System.Collections.Generic;

public class UIClassAttributeManager{
    public UIClassAttributeManager(){
        

        
        UIClass._add("UIAttributeManager", new UIScrollViewInfo(){
            type = "UIAttributeManager",
            base_type = "UIAttributeManager",
            background_key = "ui_RoundedIcon_32",
            PixelsPerUnitMultiplier = 1,
            prefab_key = "ScrollView",
            // sizeDelta = new (96*1 + 16 + 16, 32*3 + 4*2 + 16 + 16),
            // padding = new RectOffset(16, 16, 16, 16),
            paddingLeft = 16, paddingRight = 16, paddingTop = 16 + 8*2 + 16*2, paddingBottom = 16 + 8*2 + 16*2,
            spacing = new (16, 16),
            cellSize = new (192, 64),
            constraintCount = 1,
            anchoredPosition = new (8, -8),
            interactions = new List<string>() {
                "UIDrag",
            },
            items = new(){
                new() {
                    type = "UIExecuteCommandFromMessage", sizeDelta = new (192, 64), messageID = "UIExecuteCommand"
                },
                new() {
                    type = "UIInputField", sizeDelta = new (192, 64), messageID = "UIExecuteCommand"
                },
                new() {
                    type = "UIHighlight_a0.5_ScrollPass2Parent", sizeDelta = new (192, 64),
                },
                new() {
                    type = "UIHighlight_a0.5_ScrollPass2Parent", sizeDelta = new (192, 64),
                },
                new() {
                    type = "UIOpenAttributeManager", sizeDelta = new (192, 64),
                },
            },
            subUIs = new(){
                new() { type = "UICloseButtom", sizeDelta = new(16*2, 16*2), anchoredPosition = new(-8*2, -8*2) },
                new() { type = "UIResizeButtom", background_key="", sizeDelta = new(16*2, 16*2), anchoredPosition = new(-8*2, 8*2) },

            }
        });
        
    }
}