using UnityEngine;

public class ObjectMoveImpulseKeyX: ObjectMoveBase{
    public ObjectMoveImpulseKeyX(ObjectBase Base): base(Base){
    }

    protected override void _act_move(KeyPos input) { 
        Vector2 direction = new(input.x, 0);
        _Base._rb.AddForce(direction, ForceMode2D.Impulse);
    }
}