using System.Collections.Generic;

public class ObjectClassBasic{
    public ObjectClassBasic(){

        ObjectClass._add("asd", new (){
            class_type = "asd", 
            prefab_key = "obj_default",
            sprite_key = "obj_asd",
            tags = new(){
                {"identity", new(){ "player" } }
            }
        });

    }
}