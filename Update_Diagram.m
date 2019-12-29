function Update_Diagram(M, nT)
    global h
    persistent lnt
    if isempty(lnt)
        lnt = 0;
    end
    if nT < lnt 
        for j = nT+1:lnt
           set(h{j}, 'XData', NaN, 'YData', NaN);
        end
    end
    lnt = nT;
    r_t = zeros(nT,1);  % Range vector
    angle_t = r_t;  % Angle vector
         for j = 1:nT
            r_t(j,1) = M(5 + (j-1)*5);
            if M(7 + (j-1)*5) > 65000
                angle_t(j,1)=M(7 + (j-1)*5) - 65536;
            else
                angle_t(j,1)=M(7 + (j-1)*5);
            end
            set(h{j}, 'XData', -r_t(j,1)*sind(angle_t(j,1)), 'YData', r_t(j,1)*cosd(angle_t(j,1)));
         end
         pause(0.000001);
end