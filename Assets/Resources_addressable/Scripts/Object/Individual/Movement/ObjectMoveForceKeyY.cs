using UnityEngine;

public class ObjectMoveForceKeyY: ObjectMoveBase{
    public ObjectMoveForceKeyY(ObjectBase Base): base(Base){
    }

    protected override void _act_move(KeyPos input) { 
        Vector2 direction = new(0, input.y);
        _Base._rb.AddForce(direction * 5, ForceMode2D.Force);
    }
}