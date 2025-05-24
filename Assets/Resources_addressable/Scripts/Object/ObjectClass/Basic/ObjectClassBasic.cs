public class ObjectClassBasic{
    public ObjectClassBasic(){

        ObjectClass._add("asd", new (){
            class_type = "asd", 
            prefab_key = "obj_asd",
            sprite_key = "Sprite_Object_asd",
            tags = new(){
                {"identity", new(){ nameof(ObjectAsPlayer), nameof(ObjectAsImpactTrigger) } },
                {"movement", new(){ nameof(ObjectMoveForceKeyX), nameof(ObjectMoveImpulseKeyY) } },
            }
        });


        ObjectClass._add("NonEntity", new (){
            class_type = "NonEntity", 
            prefab_key = "obj_default",
            tags = new(){
                {"identity", new(){ nameof(ObjectAsPlayer), nameof(ObjectAsImpactTrigger), nameof(ObjectAsAgravic), nameof(ObjectAsNoCollision) } },
                {"movement", new(){ nameof(ObjectMoveForceKey), nameof(ObjectMoveImpulseKey) } },
            }
        });

    }
}