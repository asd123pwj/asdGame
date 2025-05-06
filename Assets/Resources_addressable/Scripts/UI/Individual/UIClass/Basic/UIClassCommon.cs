using System.Collections.Generic;

public class UIClassCommon{
    public UIClassCommon(){

        UIClass._add("UICloseButtom", new(){
            class_type = "UICloseButtom",
            background_key = "ui_3_16",
            anchorMin = new(1, 1), anchorMax = new(1, 1), pivot = new (1, 1), 
            sizeDelta = new(16, 16),
            interactions = new List<string>() {
                nameof(UIClickClose),
            },
        });

        
        UIClass._add("UIToggleButtom", new(){
            class_type = "UIToggleButtom",
            background_key = "Empty",
            sizeDelta = new (120, 40),
            interactions = new List<string>() {
                nameof(UIToggle),
            },
        });

        
        UIClass._add("UIResizeButtom", new(){
            class_type = "UIResizeButtom",
            background_key = "ui_4_16",
            anchorMin = new(1, 0), anchorMax = new(1, 0), pivot = new (1, 0), 
            sizeDelta = new (16, 16),
            interactions = new List<string>() {
                // "UISetTop",
                nameof(UIResizeScaleConstrait),
            },
        });
        
        
        UIClass._add("UIThumbnail", new (){
        // readonly public static UIInfo UIThumbnail = new() {
            class_type = "UIThumbnail",
            base_type = "UIThumbnail",
            interactions = new List<string>() {
                // "UISetTop",
                nameof(UIDragInstantiate),
            },
        });
    }
}