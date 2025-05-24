using UnityEngine;

public class ObjectMoveForceKeyX: ObjectMoveBase{
    public ObjectMoveForceKeyX(ObjectBase Base): base(Base){
    }

    protected override void _act_move(KeyPos input) { 
        Vector2 direction = new(input.x, 0);
        _Base._rb.AddForce(direction * 5, ForceMode2D.Force);
        Debug.Log(_Base.status[nameof(ObjectContactCheckGround)]);
    }
}