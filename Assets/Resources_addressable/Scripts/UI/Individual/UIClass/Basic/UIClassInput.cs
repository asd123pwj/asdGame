using System.Collections.Generic;

public class UIClassInput{
    public UIClassInput(){
        
        UIClass._add("UIInputField", new UIInputFieldInfo(){
        // readonly public static UIInputFieldInfo UIInputField = new() {
            type = "UIInputField",
            base_type = "UIInputField",
            prefab_key = "InputField",
            background_key = "ui_RoundedIcon_8", PixelsPerUnitMultiplier=1, 
            sizeDelta = new (400, 50),
            // enableNavigation = true,
            interactions = new List<string>() {
                // "UISetTop",
                "UISubmit",
                // "UIDrag",
            }
        });

        
    }
}