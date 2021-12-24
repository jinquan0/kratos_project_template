func (s *Jqapi7Service) ProcLogic(ctx context.Context, req *pb.Request) (*pb.Reply, error) {
        msg:=SelectData(GetInteger_Id(req.String()))
        return &pb.Reply{Message: msg}, nil
}
