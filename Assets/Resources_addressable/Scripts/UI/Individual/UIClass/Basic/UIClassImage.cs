using System.Collections.Generic;

public class UIClassImage{
    public UIClassImage(){

        UIClass._add("UIImage", new (){
            type = "UIImage", //sizeDelta = new(0, 0),
            // anchorMin = new(0, 0), anchorMax = new(0, 1), pivot = new (0.5f, 0.5f), 
            interactions = new List<string>() {
                "UISetTop",
            },
        });

        
        UIClass._add("UIHighlight_a0.5", new (){
            type="UIHighlight_a0.5",
            background_key="p5_a0.5", 
            sizeDelta = new(16, 16), 
            interactions = new List<string>() {
                "UISetTop",
            },
        });
    }
}