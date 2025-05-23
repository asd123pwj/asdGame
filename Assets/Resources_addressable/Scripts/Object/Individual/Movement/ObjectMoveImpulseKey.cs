using UnityEngine;

public class ObjectMoveImpulseKey: ObjectMoveBase{
    public ObjectMoveImpulseKey(ObjectBase Base): base(Base){
    }

    protected override void _act_move(KeyPos input) { 
        Vector2 direction = new(input.x, input.y);
        _Base._rb.AddForce(direction, ForceMode2D.Impulse);
    }
}