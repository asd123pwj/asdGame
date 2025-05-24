public class ObjectAsNoCollision: ObjectAsBase{
    bool original_collider_status;

    public ObjectAsNoCollision(ObjectBase Base): base(Base){}

    public override void _apply(){
        original_collider_status = _Base._collider.enabled;
        _Base._collider.enabled = false;
    }

    public override void _clear(){
        _Base._collider.enabled = original_collider_status;
    }
}