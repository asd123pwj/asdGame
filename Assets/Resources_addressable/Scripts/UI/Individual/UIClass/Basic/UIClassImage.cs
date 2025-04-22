using System.Collections.Generic;

public class UIClassImage{
    public UIClassImage(){

        UIClass._add("UIImage", new (){
            class_type = "UIImage", //sizeDelta = new(0, 0),
            // anchorMin = new(0, 0), anchorMax = new(0, 1), pivot = new (0.5f, 0.5f), 
            interactions = new List<string>() {
                // "UISetTop",
            },
        });

        UIClass._add("UISeparator", new (){
            class_type = "UISeparator", 
            PixelsPerUnitMultiplier = 1,
            background_key="ui_Separator_Horizontal",
        });
        
        UIClass._add("UITitleSeparator", new (){
            class_type = "UITitleSeparator", 
            PixelsPerUnitMultiplier = 1,
            anchorMin = new(0, 1f), anchorMax = new(1, 1f), sizeDelta = new(0, 8),
            background_key="ui_Separator_Horizontal",
        });
        
        UIClass._add("UIHighlight_a0.5", new (){
            class_type="UIHighlight_a0.5",
            background_key="p5_a0.5", 
            sizeDelta = new(16, 16), 
        });
        
        UIClass._add("UIOpenChangeTriggerMenu", new (){
            class_type="UIHighlight_a0.5",
            background_key="ui_RoundedIcon_8", PixelsPerUnitMultiplier=1, 

        });
        
    
        UIClass._add("UIHighlight_a0.5_ScrollPass2Parent", new (){
            class_type="UIHighlight_a0.5_ScrollPass2Parent",
            background_key="p5_a0.5", 
            sizeDelta = new(16, 16), 
            interactions = new List<string>() {
                // "UISetTop",
                "UIPassScroll2Parent",
            },
        });
    }
}