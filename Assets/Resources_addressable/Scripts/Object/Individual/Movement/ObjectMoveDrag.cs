public class ObjectMoveDrag: ObjectMoveBase{
    public ObjectMoveDrag(ObjectBase Base): base(Base){
        _Base._rb.drag = 1;
    }

    protected override bool _check(KeyPos input) { return false; }
}