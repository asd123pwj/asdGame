using UnityEngine;

public class ObjectAbilMoveTeleport: ObjectAbilMoveBase{
    public ObjectAbilMoveTeleport(ObjectConfig config, float cooldown, float wait, int uses): this(config, cooldown, wait, uses, -1){}
    public ObjectAbilMoveTeleport(ObjectConfig config, float cooldown, float wait, float duration): this(config, cooldown, wait, -1, duration){}
    public ObjectAbilMoveTeleport(ObjectConfig config, float cooldown, float wait, int uses, float duration): base(config, cooldown, wait, uses, duration){
        _name = "teleport";
    }

    protected override void _act_move(KeyPos input) { 
        teleport(input);
    }

    void teleport(KeyPos input){
        Vector2 pos = input.mouse_pos_world;
        _Config._self.transform.position = pos;
    }
}
