using System.Collections.Generic;

public class UIClassBackpack{
    public UIClassBackpack(){
        UIClass._add("UIBackpack", new(){
        // readonly public static UIInfo UIBackpack = new() {
            class_type = "UIBackpack",
            // base_type = "UIBase",
            background_key = "ui_1",
            sizeDelta = new(1600, 900), 
            subUIs = new(){
                new() { class_type = "UICloseButtom" },
                new() { class_type = "UIResizeButtom" },
            },
            interactions = new List<string>() {
                // "UISetTop",
                "UIDrag",
                "UIOpenRightMenu",
                // "UIClickCloseRightMenu",
            },
        });
        
    }
}