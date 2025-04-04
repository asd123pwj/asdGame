using System.Collections.Generic;

public class UIClassAttributeManager{
    public UIClassAttributeManager(){
        
        
        UIClass._add("UIAttributeManager", new (){
        // readonly public static UIInfo UIRightMenuInteractionManager = new() {
            type = "UIAttributeManager",
            // base_type = "UIRightMenuInteractionManager",
            background_key = "ui_RoundedIcon_32",
            enableNavigation = true,
            sizeDelta = new (96*1 + 16 + 16 + 16, 32*3 + 4*2 + 16 + 16 + 16),
            PixelsPerUnitMultiplier = 1,
            interactions = new List<string>() {
                "UISetTop",
                // "UIDeselectClose",
            },
            subUIs = new(){
                new UIScrollViewInfo() {
                    type = "UIScrollView",
                    base_type = "UIScrollView",
                    background_key = "",
                    sizeDelta = new (96*1 + 16 + 16, 32*3 + 4*2 + 16 + 16),
                    padding = new (4, 4, 4, 4),
                    spacing = new (16, 16),
                    cellSize = new (96, 32),
                    constraintCount = 1,
                    anchoredPosition = new (8, -8),
                    interactions = new List<string>() {
                        "UISetTop",
                    },
                    items = new(){
                        new() {
                            type = "UIExecuteCommand", sizeDelta = new (96, 32), messageID = "UIExecuteCommand"
                        },
                        new() {
                            type = "UIInputField", sizeDelta = new (96, 32), messageID = "UIExecuteCommand"
                        },
                        new() {
                            type = "UIHighlight_a0.5_ScrollPass2Parent", sizeDelta = new (96, 32),
                        },
                        new() {
                            type = "UIHighlight_a0.5_ScrollPass2Parent", sizeDelta = new (96, 32),
                        },
                        new() {
                            type = "UIHighlight_a0.5_ScrollPass2Parent", sizeDelta = new (96, 32),
                        },
                    },
                    subUIs = new()
                }
            }
        });
    }
}