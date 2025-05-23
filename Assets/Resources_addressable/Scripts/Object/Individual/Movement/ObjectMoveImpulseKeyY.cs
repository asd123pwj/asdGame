using UnityEngine;

public class ObjectMoveImpulseKeyY: ObjectMoveBase{
    public ObjectMoveImpulseKeyY(ObjectBase Base): base(Base){
        _cooldown = 0.5f;
    }

    protected override void _act_move(KeyPos input) { 
        Vector2 direction = new(0, input.y);
        _Base._rb.AddForce(direction * 5, ForceMode2D.Impulse);
    }
}