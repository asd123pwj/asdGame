using System.Collections.Generic;

public class UIClassImage{
    public UIClassImage(){

        UIClass._add("UIImage", new (){
        // readonly public static UIInfo UIImage = new(){
            type = "UIImage", //sizeDelta = new(0, 0),
            // anchorMin = new(0, 0), anchorMax = new(0, 1), pivot = new (0.5f, 0.5f), 
            interactions = new List<string>() {
                "UISetTop",
            },
        });

        
    }
}