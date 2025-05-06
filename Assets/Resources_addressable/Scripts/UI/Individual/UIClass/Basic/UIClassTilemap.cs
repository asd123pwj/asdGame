using System.Collections.Generic;

public class UIClassTilemap{
    public UIClassTilemap(){

        
        UIClass._add("UITileThumb", new (){
            class_type="UITileThumb",
            background_key="p5_a0.5", 
            sizeDelta = new(16, 16),
            interactions = new List<string>(){
                nameof(UIUpdateSelectedTileByUIName)
            }
        });
        
    }
}