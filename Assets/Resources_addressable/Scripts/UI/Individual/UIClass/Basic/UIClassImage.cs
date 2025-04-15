using System.Collections.Generic;

public class UIClassImage{
    public UIClassImage(){

        UIClass._add("UIImage", new (){
            type = "UIImage", //sizeDelta = new(0, 0),
            // anchorMin = new(0, 0), anchorMax = new(0, 1), pivot = new (0.5f, 0.5f), 
            interactions = new List<string>() {
                // "UISetTop",
            },
        });

        UIClass._add("UISeparator", new (){
            type = "UISeparator", 
            PixelsPerUnitMultiplier = 1,
            background_key="ui_Separator_Horizontal",
        });
        
        UIClass._add("UITitleSeparator", new (){
            type = "UITitleSeparator", 
            PixelsPerUnitMultiplier = 1,
            anchorMin = new(0, 1f), anchorMax = new(1, 1f), sizeDelta = new(0, 8),
            background_key="ui_Separator_Horizontal",
        });
        
        UIClass._add("UIHighlight_a0.5", new (){
            type="UIHighlight_a0.5",
            background_key="p5_a0.5", 
            sizeDelta = new(16, 16), 
            interactions = new List<string>() {
                // "UISetTop",
            },
        });
        
    
        UIClass._add("UIHighlight_a0.5_ScrollPass2Parent", new (){
            type="UIHighlight_a0.5_ScrollPass2Parent",
            background_key="p5_a0.5", 
            sizeDelta = new(16, 16), 
            interactions = new List<string>() {
                // "UISetTop",
                "UIScrollPass2Parent",
            },
        });
    }
}