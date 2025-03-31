using System.Collections.Generic;

public class UIClassCommon{
    public UIClassCommon(){

        UIClass._add("UICloseButtom", new(){
            type = "UICloseButtom",
            background_key = "ui_3_16",
            anchorMin = new(1, 1), anchorMax = new(1, 1), pivot = new (1, 1), 
            sizeDelta = new(16, 16),
            interactions = new List<string>() {
                "UIClickClose",
            },
        });

        
        UIClass._add("UIToggleButtom", new(){
            type = "UIToggleButtom",
            background_key = "Empty",
            sizeDelta = new (120, 40),
            interactions = new List<string>() {
                "UIToggle",
            },
        });

        
        UIClass._add("UIResizeButtom", new(){
            type = "UIResizeButtom",
            background_key = "ui_4_16",
            anchorMin = new(1, 0), anchorMax = new(1, 0), pivot = new (1, 0), 
            sizeDelta = new (16, 16),
            interactions = new List<string>() {
                "UISetTop",
                "UIResizeScaleConstrait",
            },
        });
        
        
        UIClass._add("UIThumbnail", new (){
        // readonly public static UIInfo UIThumbnail = new() {
            type = "UIThumbnail",
            base_type = "UIThumbnail",
            interactions = new List<string>() {
                "UISetTop",
                "UIDragInstantiate",
            },
        });
    }
}