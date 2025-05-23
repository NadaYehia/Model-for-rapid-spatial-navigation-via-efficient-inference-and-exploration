
classdef OptimizerClass_smoothness_and_PL< handle
    properties
        optimized_x=[];
        optimized_y=[];
        param=[];
    end

    methods

        function total_cost=loss(obj,p,arena,rho,no_anchors,w1,w2,dt)
        x_op=[];
        y_op=[];
        speed_conca=[];
        heading_conca=[];
        
        phi0_n=p(1:no_anchors-1);
        r=p(no_anchors:2*no_anchors-1);
        theta=p(2*no_anchors:end);
        
        for n=1:numel(r)-1
           %% Equation (3)
           S_theta(n)= theta(n)+atan2( r(n+1)*sin(theta(n+1)-theta(n)),...
                                    r(n+1)*cos(theta(n+1)-theta(n)) -r(n)  );

        end
        
%         % calculate the difference in heading angles at the anchor points.
%         % dOmega= theta at t=1 of the current segment - theta at t=T of the 
%         % previous segment.

        for n=2:numel(r)-1

            %% Equation 35
            hd_previous=wrapToPi(S_theta(n-1)+ phi0_n(n-1));
            hd_next=wrapToPi(S_theta(n)-phi0_n(n));
            domega=wrapToPi(hd_next-hd_previous);
            K(n)=abs(domega);
        end



        for n=1:size(r,2)-1

        %% Equation 10
        Dx=(-r(n)*cos(theta(n))) +(r(n+1)*cos(theta(n+1)));

        %% Equation 11
        Dy=(-r(n)*sin(theta(n))) +(r(n+1)*sin(theta(n+1)));
        
                       
        phi0_n(n)=wrapToPi(phi0_n(n));
        abs_phi0_n=abs(phi0_n(n));
        dir_rotation=sign(phi0_n(n));

        %% Equation 26
        epsi=((abs_phi0_n-pi/2));
         
        %% Equation 9
        D(n)=sqrt(Dx^2 +Dy^2);
        %% Equation 30
        vmax_n=rho*((4*pi)+(4*epsi));
        vmax_d= (2*pi)*(sinc(epsi/pi));
        vmax= (vmax_n/vmax_d);
        
        %% Equation 29
        T=(2*D(n))/rho;
        
            if(isnan(vmax))
                error('check vmax calculations');
            end
        
        % use the functional form to produce x,y points in space
        w=(2*pi)/(T);
        t1=[0:dt:T/2];
        
        %% Equation 31
        speed= [sin(w.*t1)];
        speed= (vmax).*speed;
        %% Equation 8
        heading= ( ((4*dir_rotation*abs_phi0_n)/T) .*t1)+( (S_theta(n)) -(dir_rotation*abs_phi0_n));
        heading=wrapToPi(heading);
        
        % calculate the x&y points of a trajectory segment
        pos_x=zeros(1,size(heading,2));
        pos_y=zeros(1,size(heading,2));
        dx= zeros(1,size(heading,2));
        dy=zeros(1,size(heading,2));
        dx(1)=r(n)*cos(theta(n));
        dy(1)=r(n)*sin(theta(n));
        [temp_dx,temp_dy] = pol2cart(heading(2:end),speed(2:end).*dt);
        dx(2:end)=temp_dx;
        dy(2:end)=temp_dy;
        pos_x=cumsum(dx);
        pos_y=cumsum(dy);
        
        %% Equation 33
        Pl(n)=( sum(vecnorm([diff(pos_x)' diff(pos_y)'],2,2)) );

        % confine the trajectory segment to the arena enclosure
        pos_x( find(pos_x>arena(2)) )=arena(2); 
        pos_x( find(pos_x<arena(1)) )=arena(1);
        pos_y( find(pos_y>arena(4)) )=arena(4); 
        pos_y( find(pos_y<arena(3)) )=arena(3); 
        
        
        
        x_op=[x_op, pos_x(1:end)];
        y_op=[y_op, pos_y(1:end)];
        speed_conca=[speed_conca,speed];
        heading_conca=[heading_conca, heading];
        
        pos_y=[];
        pos_x=[];
        
        end
        % Store the optimized trajectory and parameters:
        obj.optimized_x=x_op;
        obj.optimized_y=y_op;
        obj.param=p;

        % sum of anglular changes at the anchor points 
        %% Equation 34
         kappa=sum(K);

        %% Equation 32 
        total_cost= (w1*sum(Pl))+((w2)*kappa);
       
        end


    
    end
 


end

