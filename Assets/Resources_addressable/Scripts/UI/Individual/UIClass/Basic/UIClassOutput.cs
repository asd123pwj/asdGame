using System.Collections.Generic;

public class UIClassOutput{
    public UIClassOutput(){
        
        UIClass._add("UIScrollText", new UIScrollTextInfo(){
        // readonly public static UIScrollTextInfo UIScrollText = new(){
            type = "UIScrollText",
            base_type = "UIScrollText",
            prefab_key = "ScrollText",
            background_key = "ui_2", PixelsPerUnitMultiplier=2,
            // sizeDelta = new(0, 0),
            // anchorMin = new(0.01f, 0.01f), anchorMax = new(0.99f, 0.99f), pivot = new (0.5f, 0.5f), 
            enableNavigation = true,
            interactions = new List<string>() {
                "UISetTop",
            },
        });
        
    }
}