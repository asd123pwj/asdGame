using System.Collections.Generic;

public class ObjectClassBasic{
    public ObjectClassBasic(){

        ObjectClass._add("asd", new (){
            class_type = "asd", 
            prefab_key = "Obj_prefab_asd",
            sprite_key = "Obj_sprite_asd",
            tags = new(){
                {"identity", new(){ "player" } }
            }
        });

    }
}