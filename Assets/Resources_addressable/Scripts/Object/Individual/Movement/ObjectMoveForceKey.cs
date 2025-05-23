using UnityEngine;

public class ObjectMoveForceKey: ObjectMoveBase{
    public ObjectMoveForceKey(ObjectBase Base): base(Base){
    }

    protected override void _act_move(KeyPos input) { 
        Vector2 direction = new(input.x, input.y);
        Debug.Log("direction: " + direction);
        _Base._rb.AddForce(direction * 5, ForceMode2D.Force);
    }
}