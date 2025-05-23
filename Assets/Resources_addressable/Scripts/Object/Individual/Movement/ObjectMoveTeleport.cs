using UnityEngine;

public class ObjectMoveTeleport: ObjectMoveBase{
    public ObjectMoveTeleport(ObjectBase Base): base(Base){
        _cooldown = 0.5f;
    }

    protected override void _act_move(KeyPos input) { 
        Vector2 pos = input.mouse_pos_world;
        _Base._self.transform.position = pos;
    }
}