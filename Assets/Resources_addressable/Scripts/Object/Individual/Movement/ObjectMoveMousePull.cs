using UnityEngine;

public class ObjectMoveMousePull: ObjectMoveBase{
    public ObjectMoveMousePull(ObjectBase Base): base(Base){
    }

    protected override void _act_move(KeyPos input) { 
        Debug.Log(input.x);
        Vector2 direction = (input.mouse_pos_world - _Base._rb.position);
        _Base._rb.AddForce(direction, ForceMode2D.Impulse);
    }
}