/**
* Name: BCNWB Prototype
* Based on the internal empty template. 
* Author: cgonzalez
* Tags: 
*/


model BCNWB_Prototype

/* Use of urban environment by wild boar in the city of Barcelona, Spain */

global {
	//FILES
	date starting_date <- date([2020,1,1,0,0,0]);
	file building_shapefile <- file("../includes/BUILDEFINI.shp");
	file wia_shapefile <- file("../includes/WIACNP.shp");
	file road_shapefile <- file("../includes/ROADDEF.shp");
	file initial_wwb <- file("../includes/iniciowwb.shp");
	file initial_swb <- file("../includes/INCI2010.shp");
	geometry shape <- envelope(road_shapefile);
	graph road_network;
	
	//TIME
	float step <- 60 #mn;
	float calcul_day<- ((1/24));//para los calculos de cada dia
	float calcul_month<-((1/30)*calcul_day);//para los calculos de cada mes
	float calcul_year<-((1/365)*calcul_day);//para los calculos de cada year
	bool same_day<- false update: current_hour between(8,20);
	bool is_weekend<- false update: current_day >=5;
	int current_hour update: int (time / #hour) mod 24; 
	int current_month update: int (time / #month) mod 12 min: 1;
	int current_week update: int (time / #week) mod 4 min: 1;
	int current_day update: int (time / #day) mod 7 min: 1;
	int current_daysim update: int (time / #day)mod 365 min: 1;
	bool scarce_period <- false update: current_month >=5 and current_month <=10;

	bool is_reprotime <- true update: current_month <= 4 or current_month >= 10 ;
	float annual_EV<-rnd(-0.15,0.15);
	
	//Citizen
	int nb_people -> {length (normal_citi+pet_owners+feeder_citi)};
	int min_work_start <- 1;
	int max_work_start <- 12;
	int min_work_end <- 16; 
	int max_work_end <- 23; 
	int min_natu_start <- 3;
	int max_natu_start <- 15;
	int min_natu_end <- 16; 
	int max_natu_end <- 23; 
	float min_speed <- 1.0 #km / #h;
	float max_speed <- 5.0 #km / #h; 

	
	//animal
	
	int nb_agressions <-0;
	int nb_feeding <-0;
	int nb_encounters <-0;
	int nb_interactions ->  {length (nb_encounters)};
	int nb_attacks->  {length (nb_agressions)};
	int nb_feed_events-> {length (nb_feeding)};
	
	float detect_range<-1000#m;
	float habit_prob<- 0.15;
	
	//Parámetros para PD
	//Abundances SWB
	int nb_M_Awb_init<- 22;
	int nb_F_Awb_init<- 23;
	int nb_M_Ywb_init<- 32;
	int nb_F_Ywb_init<- 35;
	int nb_M_Jwb_init<- 90;
	int nb_F_Jwb_init<- 91;
	//Abundances WWB
	int nb_WM_Awb_init<- 26;
	int nb_WF_Awb_init<- 27;
	int nb_WM_Ywb_init<- 39;
	int nb_WF_Ywb_init<- 42;
	int nb_WM_Jwb_init<- 106;
	int nb_WF_Jwb_init<- 108;
	
	//Fertility
	float reproduction_distance <- 30.0#m;
	int nb_max_ofs <- 5;
	float sex_ratio <- 0.5;
	
	float proba_reproduce_adults_ini <- (0.15*calcul_year);
	float proba_reproduce_yearlings_ini <- (0.6*calcul_year);
	float proba_reproduce_juveniles_ini <- (0.7*calcul_year);
	float proba_reproduce_adults ;
	float proba_reproduce_yearlings ;
	float proba_reproduce_juveniles;

	//Mortlity-->
	float proba_die_F_Jwb_ini <- (0.29*calcul_year);
	float proba_die_F_Ywb_ini <- (0.35*calcul_year);
	float proba_die_F_Awb_ini <-(0.39*calcul_year);
	float proba_die_M_Jwb_ini <- (0.3*calcul_year);
	float proba_die_M_Ywb_ini <- (0.43*calcul_year);
	float proba_die_M_Awb_ini <- (0.35*calcul_year);
	float proba_die_F_Jwb ;
	float proba_die_F_Ywb ;
	float proba_die_F_Awb ;
	float proba_die_M_Jwb ;
	float proba_die_M_Ywb ;
	float proba_die_M_Awb ;
	
	list<animal1> all_toge;

	list<animal2> all_toge2;

	list<animal> all_wb;
	list<animal> all_wbS;
	list<animal> ALLall;
	list<animal>ALLallS;


reflex update_values{	
		all_toge<-  (agents of_generic_species animal1 );
		all_toge2<-  (agents of_generic_species animal2);
		ALLall <-all_toge+all_toge2;
		ALLallS <-((agents of_generic_species animal1) where each.agressive_state) ;
	}

	int nb_People->{length (people)};
	int nb_M_Awb -> {length (M_Awb)};
	int nb_F_Awb -> {length (F_Awb)};
	int nb_M_Jwb -> {length (M_Jwb)};
	int nb_F_Jwb -> {length (F_Jwb)};
	int nb_M_Ywb -> {length (M_Ywb)};
	int nb_F_Ywb-> {length (F_Ywb)};
	int nb_all_wb -> {length (all_toge)};
	int nb_WM_Awb -> {length (WM_Awb)};
	int nb_WF_Awb -> {length (WF_Awb)};
	int nb_WM_Jwb -> {length (WM_Jwb)};
	int nb_WF_Jwb -> {length (WF_Jwb)};
	int nb_WM_Ywb -> {length (WM_Ywb)};
	int nb_WF_Ywb-> {length (WF_Ywb)};
	int nb_Wall_wb -> {length (all_toge2)};
	int nb_all-> {length (ALLall)};
	
	//building 
	list<building> living_places;
	list<building> working_places;
	list<building> health_places;
	list<building> leissure_places;
	
	//WIA
	list<wia> resting_places;
	list<wia> feeding_places;
	
   action store {      
        write "===========S===== START SAVE + self " + " - " + cycle ;		
		write "Save of simulation : " + save_simulation('saveSimuP1.gsim');
		write "================ END SAVE + self " + " - " + cycle ;	      
    }  
	
	action saveroad{
		save cell to:"../results/protostop.shp" type:"shp" attributes: ["ID":: int(self),"wb_presence":: (wb_presence), 
		"wb_attacks"::(wb_attacks), "wb_feed_events"::(wb_feed_events),"HWIs"::(HWI)];
}
	reflex end_simulation when: (current_daysim >=366) or (nb_all = 0) {
		do pause;
		save cell to:"../results/prototot.shp" type:"shp" attributes: ["ID":: int(self),"wb_presence":: (wb_presence), 
		"wb_attacks"::(wb_attacks), "wb_feed_events"::(wb_feed_events)];
	}
	

	
	reflex stochasticity when: (step = 1){
		proba_reproduce_adults<-  proba_reproduce_adults_ini* annual_EV;
	 	proba_reproduce_yearlings <-  proba_reproduce_yearlings_ini* annual_EV;
	 	proba_reproduce_juveniles<-  proba_reproduce_juveniles_ini* annual_EV;
	
	//Mortlity-->
	 proba_die_F_Jwb <-  proba_die_F_Jwb_ini* annual_EV;
	 proba_die_F_Ywb <-  proba_die_F_Ywb_ini* annual_EV;
	 proba_die_F_Awb <-  proba_die_F_Awb_ini* annual_EV;
	 proba_die_M_Jwb <-  proba_die_M_Jwb_ini* annual_EV;
	 proba_die_M_Ywb <-  proba_die_M_Ywb_ini* annual_EV;
	 proba_die_M_Awb <-  proba_die_M_Awb_ini* annual_EV;
	 float contador_EV;
	 contador_EV<-contador_EV+calcul_year;
	 if (contador_EV >=365) {
	 	annual_EV <- rnd(-0.15,0.15);
	 	 contador_EV<-0.0;
	 }
	}
	
	init {
		
	create initlocw from: initial_wwb;
	create initlocs from: initial_swb;
	create building from: building_shapefile with: [type::string(read ("NATURE")) ,district::string(get ("DIST"))] ;
	living_places <- building  where (each.type="live") ;
	ask living_places{
			type <- "living place";}	
			
	working_places <- building  where (each.type="work") ;
	ask working_places{
			type <- "working place";}
		
	health_places <- building  where (each.type="health") ;
	ask health_places{
			type <- "health place";}
			
	leissure_places <- building  where (each.type="leissure") ;
	ask leissure_places{
			type <- "leissure place";}
			
	create wia from: wia_shapefile with:  [maxFoodN::float(get("MXFOOD")),urban::string(read ("URBAN")), 
		type::string(read ("NATURE")),surface::float(get("surface")), 
		humanUse::string(read ("humanuse"))	];
	
	resting_places <- wia where (each.type= "rest" );
	ask resting_places{
			type <- "resting place";}
		
	feeding_places <- wia  where (each.type= "food"); 
	
	ask feeding_places{		
			type <- "feeding place";
			}
	
	ask feeding_places where (each.urban= "SI" ){
		is_urban<-true;
	}


	create road from: road_shapefile with: [USE::string(get ("NATURE")), TYPE::string(get ("TYPE"))];
    road_network <- as_edge_graph(road);
		
create feeder_citi from: csv_file("../includes/ALIM.csv", true) with: [W_D::string(get ("W_D")), R_D::string(read ("R_D"))] {
	    	speed <- min_speed + rnd (max_speed - min_speed) ;
			start_work <- min_work_start + rnd (max_work_start - min_work_start) ;
			end_work <- min_work_end + rnd (max_work_end - min_work_end) ;
			start_natu <- min_natu_start + rnd (max_natu_start - min_natu_start);
			end_natu <- min_natu_end + rnd (max_natu_end - min_natu_end) ;
			living_place<- one_of(living_places where (each.district= R_D)) ;
			working_place <- one_of(working_places where (each.district= W_D)) ;
			//nature_place <- one_of(feeding_places);
			objective <- "resting";
			location <- any_location_in (living_place); } 
		
create pet_owners from: csv_file("../includes/MASC.csv", true) with: [W_D::string(get ("W_D")), R_D::string(read ("R_D"))] {
			speed <- min_speed + rnd (max_speed - min_speed) ;
			start_work <- min_work_start + rnd (max_work_start - min_work_start) ;
			end_work <- min_work_end + rnd (max_work_end - min_work_end) ;
			start_natu <- min_natu_start + rnd (max_natu_start - min_natu_start);
			end_natu <- min_natu_end + rnd (max_natu_end - min_natu_end) ;
			living_place <- one_of(living_places where (each.district= R_D)) ;
			working_place <- one_of(working_places where (each.district= W_D)) ;
			//nature_place <- one_of(feeding_places);
			objective <- "resting";
			location <- any_location_in (living_place); }
			 
create normal_citi from: csv_file("../includes/CIUD.csv", true) with: [W_D::string(get ("W_D")), R_D::string(read ("R_D"))]{
			speed <- min_speed + rnd (max_speed - min_speed) ;
			start_work <- min_work_start + rnd (max_work_start - min_work_start) ;
			end_work <- min_work_end + rnd (max_work_end - min_work_end) ;
			start_natu <- min_natu_start + rnd (max_natu_start - min_natu_start);
			end_natu <- min_natu_end + rnd (max_natu_end - min_natu_end) ;
			living_place <- one_of(living_places where (each.district= R_D)) ;
			working_place <- one_of(working_places where (each.district= W_D)) ;
			//nature_place <- one_of(feeding_places);
			objective <- "resting";
			location <- any_location_in (living_place); } 	    


//Creation of the Swb agents	  
 		create M_Jwb number: nb_M_Jwb_init{
			location <- any_location_in(one_of(initlocs));
			age_in_months<- rnd(5.0,10.0);

      		}
      	create F_Jwb number: nb_F_Jwb_init{
			location <- any_location_in(one_of(initlocs));
			age_in_months<- rnd(5.0,10.0);

      		}
      	create M_Ywb number: nb_M_Ywb_init{
			location <- any_location_in(one_of(initlocs));
			age_in_months<- rnd(15.0,20.0);

      		}
      	create F_Ywb number: nb_F_Ywb_init{
			location <- any_location_in(one_of(initlocs));
			age_in_months<- rnd(15.0,20.0);		
	
      		}
      		
      		ask (nb_F_Ywb_init*0.1) among F_Ywb{
			pregnant <- true;
			contador_pregnant<-rnd(10,2800);
			}
		
      	create M_Awb number: nb_M_Awb_init{
			location <- any_location_in(one_of(initlocs));
			age_in_months<- rnd(24.0,80.0);

      		}
     	create F_Awb number: nb_F_Awb_init{
			location <- any_location_in(one_of(initlocs));
			age_in_months<- rnd(24.0,80.0);

      		}
			
			ask (nb_F_Awb_init*0.3) among F_Awb{
			pregnant <- true;
			contador_pregnant<-rnd(10,2800);
			}
			ask (0.053) among F_Awb+M_Awb{
			agressive_state <- true;
			}
			
//Creation of the Wwb agents	  
 		create WM_Jwb number: nb_WM_Jwb_init{
			location <- any_location_in(one_of(initlocw));
			age_in_months<- rnd(5.0,10.0);

      		}
      	create WF_Jwb number: nb_WF_Jwb_init{
			location <- any_location_in(one_of(initlocw));
			age_in_months<- rnd(5.0,10.0);

      		}
      	create WM_Ywb number: nb_WM_Ywb_init{
			location <- any_location_in(one_of(initlocw));
			age_in_months<- rnd(15.0,20.0);

      		}
      	create WF_Ywb number: nb_WF_Ywb_init{
			location <- any_location_in(one_of(initlocw));
			age_in_months<- rnd(15.0,20.0);	

      		}
      		
      		ask (nb_WF_Ywb_init*0.1) among WF_Ywb{
			pregnant <- true;
			contador_pregnant<-rnd(10,2800);
			}
      		
      	create WM_Awb number: nb_WM_Awb_init{
			location <- any_location_in(one_of(initlocw));
			age_in_months<- rnd(24.0,80.0);

      		}
     	create WF_Awb number: nb_WF_Awb_init{
			location <- any_location_in(one_of(initlocw));
			age_in_months<- rnd(24.0,80.0);

      		}
			ask (nb_WF_Awb_init*0.3) among WF_Awb{
			pregnant <- true;
			contador_pregnant<-rnd(10,2800);
			}	
			
	 		
    	}    		
   	} 
   	
species initlocw schedules: []{
}

species initlocs schedules: []{	
}

species road{
	string USE;
	string TYPE;
	int usedbywb;
		aspect base {
		draw shape color: #black;//color;
	}
	
	}
	
species animal skills:[moving]{
	float proba_die_F_Jwb <- proba_die_F_Jwb_ini+ (proba_die_F_Jwb_ini* annual_EV);
	float proba_die_F_Ywb <-  proba_die_F_Ywb_ini+(proba_die_F_Ywb_ini* annual_EV);
	float proba_die_F_Awb <-  proba_die_F_Awb_ini+(proba_die_F_Awb_ini* annual_EV);
	float proba_die_M_Jwb <-  proba_die_M_Jwb_ini+(proba_die_M_Jwb_ini* annual_EV);
	float proba_die_M_Ywb <- proba_die_M_Ywb_ini+ (proba_die_M_Ywb_ini* annual_EV);
	float proba_die_M_Awb <- proba_die_M_Awb_ini+ (proba_die_M_Awb_ini* annual_EV);
	float speed <- 5 #km/#h;
	float age_in_months;
	point target;
	wia current_target;
	bool resting <- true ;
	bool need_to_rest <- true ;
	bool pregnant<- false;
	float incidence_distanceW<- 10.0 #m;
	
	reflex aging {
			age_in_months <- age_in_months + 0.00137;//el 0.23 para semana / 0.0328 para día / 0.00137HORA
	if age_in_months >= 132{
	do die;
		}
	}	
}

species animal1 parent: animal{

	bool agressive_state <- false;
	float agressive_prob<- (0.053*calcul_year);
	
	reflex speed_people {
		ask normal_citi at_distance incidence_distanceW{
			speed<-max_speed;
		}
		ask pet_owners at_distance incidence_distanceW{
			speed<-max_speed;
		}
		ask feeder_citi at_distance incidence_distanceW{
			speed<-min_speed;
		}
	}
	
	
	//resting and moving
	reflex manage_resting  {		
		if (resting) {
			need_to_rest <- (current_hour between(7,21));
			resting <- need_to_rest;
		} else { need_to_rest <- (current_hour between(7,21));}
	}	

	list<wia> reachable_feed ;
	list<wia> availa_f ;
	list<wia> availa_feed; 
	list<wia> visitados;
		
		
reflex noback {		
		reachable_feed <-((feeding_places ) at_distance detect_range);
		availa_f <-(reachable_feed ) where (each.food >= 0.2);
		
		if (not same_day){
		visitados <- visitados + current_target;		
		availa_feed<-availa_f-visitados;
		}else{	
		visitados <- [];	}
	
 }
	reflex leave when: (not resting)  and (target = nil)  {
		float quantity_food;
		ask (feeding_places overlapping self ){
		quantity_food<- food;
		}
		if 	quantity_food <= 0.10{
		
		if need_to_rest {
			current_target <-(resting_places closest_to self);
		}else if !empty (availa_feed where (each.is_urban=true)){
			availa_feed <-availa_feed where (each.is_urban=true);
			current_target <-availa_feed   closest_to self;}
			else {
				availa_feed <-availa_feed where (each.is_urban=false);
				current_target <-availa_feed  closest_to self;
			}
					
		target <- any_location_in(current_target);	}	
		else if  need_to_rest {
		current_target <-(resting_places closest_to self);			
		target <- any_location_in(current_target);
		}
	}	

   	reflex moving when: target != nil {
		path path_followed <- self goto [target::target, on::road_network, return_path:: true];
		list<geometry> segments <- path_followed.segments;
		loop line over: segments {
			float dist <- line.perimeter;
			ask road(path_followed agent_from_geometry line) { 
				usedbywb <- usedbywb + 1;
			}
		}
		if (path_followed != nil ) {
			ask (cell overlapping path_followed.shape) {
				wb_presence <- wb_presence + 1;
			}
		}
		if (location = target) {
			target <- nil;
			if (need_to_rest and (current_target.type = "resting place")) {
				resting <- true;}
		}
	}	

	reflex become_agressive when: not agressive_state {
		if flip (agressive_prob){
			agressive_state <- true;}
	}

	reflex feed when: !empty (feeding_places overlapping self){
      	ask feeding_places overlapping self {
      		if self.urban = "SI"{
      			if self.surface >= 5000 {
      				food <- food - ((2000/(self.surface)));
      			} else	 {
      			food <- food - ((1500/(self.surface)));
      		}
      		}  else{
      			food <- food - ((200/(self.surface)));
      		}
		}
		}
		

	}	

//Females
species SFW parent:animal1{
	int contador_pregnant;	
	int contador_breeding;	
	float proba_reproduce;	
	//bool is_reprotime <- false update: current_month <= 3 or current_month >= 11 ;
	float sex_ratio <- 0.5;
	bool pregnant<- false;
	reflex reproduce when: (!empty (M_Awb at_distance reproduction_distance)) and ((not pregnant) and (age_in_months >=6.0)) {
		if flip(proba_reproduce) {
		pregnant<-true;
		} 	
	}
	
	reflex reproduce2 when: (!empty (WM_Awb at_distance reproduction_distance)) and ((not pregnant) and (age_in_months >=6.0)) {
		if flip(proba_reproduce) {
		pregnant<-true;
		} 	
	}
	
	reflex reprolong when:(pregnant){
		contador_pregnant<-contador_pregnant + 1;
		if contador_pregnant >=(2832){//2832 horas que son 3 meses, 3 semanas, 3 días de gestación
			do pregnancy;
			contador_pregnant <-0;
		}
		
	}
	reflex breeding_t when: (pregnant) and ( contador_pregnant >=(2810)){
		contador_breeding<-contador_breeding + 1;
		if contador_breeding >=(2950){//5760 horas en 8 meses de cria
			pregnant<-false;	
			contador_breeding <-0;
		}
	}
	action pregnancy {		
		int nb_ofs <- 1 + rnd(0,4);
		loop times: nb_ofs{
			if flip(sex_ratio){
		create (M_Jwb) number:1{
		location <-myself.location;

}
			} else {
				create (F_Jwb) number:1{
				location <-myself.location;

		}
				}
			}			
	}

}

species WFW parent:animal2{
	int contador_pregnant;	
	int contador_breeding;	
	float proba_reproduce;	
	bool is_reprotime <- false update: current_month <= 3 or current_month >= 11 ;
	float sex_ratio <- 0.5;
	bool pregnant<- false;
	reflex reproduce when: (!empty (WM_Awb at_distance reproduction_distance)) and ((is_reprotime) and ((not pregnant) and (age_in_months >=6.0))) {
		if flip(proba_reproduce) {
		pregnant<-true;
		} 	
	}
	reflex reproduce2 when: (!empty (M_Awb at_distance reproduction_distance)) and ((is_reprotime) and ((not pregnant) and (age_in_months >=6.0))) {
		if flip(proba_reproduce) {
		pregnant<-true;
		} 	
	}
reflex reprolong when:(pregnant){
		contador_pregnant<-contador_pregnant + 1;
		if contador_pregnant >=(2832){//2832 horas que son 3 meses, 3 semanas, 3 días de gestación
			do pregnancy;
			contador_pregnant <-0;
		}
		
	}
	reflex breeding_t when: (pregnant) and ( contador_pregnant >=(2810)){
		contador_breeding<-contador_breeding + 1;
		if contador_breeding >=(2950){//5760 horas en 8 meses de cria
			pregnant<-false;	
			contador_breeding <-0;
		}
	}
	
	action pregnancy {		
		int nb_ofs <- 1 + rnd(0,4);
		loop times: nb_ofs{
			if flip(sex_ratio){
		create (M_Jwb) number:1{
		location <-myself.location;

		}
			} else {
				create (F_Jwb) number:1{
				location <-myself.location;

		 }
				}
			}			
	}

}

//SubSpecies SW

species M_Jwb parent: animal1 {
	
	reflex mortality {
	if flip(proba_die_M_Jwb) {
		do die ;
		}
	}
	
	reflex growth{
	if age_in_months >= 12{
	create (M_Ywb) number:1 {
		location <-myself.location;
		age_in_months<- 12.0;
 
			}do die;
		}
	}
	
	aspect base {
		draw square(1) color:  #blue;
	}
}

species M_Ywb parent: animal1 {
	reflex mortality {
	if flip(proba_die_M_Ywb) {
		do die ;
		}
	}
	

	reflex growth{
	if age_in_months >= 24{
	create (M_Awb) number:1 {
		location <-myself.location;
		age_in_months<- 24.0;

			}do die;
		}
	}
	
	
	aspect base {
		draw square(2) color: #blue;
	}
}

species M_Awb parent: animal1 {
	reflex mortality {
	if flip(proba_die_M_Awb) {
		do die ;
		}
	}
	
	aspect base {
		draw square(3) color: #blue;
	}
}

species F_Jwb parent: SFW {
	reflex mortality {
	if flip(proba_die_F_Jwb) {
		do die ;
		}
	}
	
	
	reflex growth{
	if age_in_months >= 12{
	create (F_Ywb) number:1 {
		location <-myself.location;
		age_in_months<- 12.0;

			}do die;
		}
	}
	
	aspect base {
		draw square(1) color: #yellow;
	}
}

species F_Ywb parent: SFW {
	reflex mortality {
	if flip(proba_die_F_Ywb) {
		do die ;
		}
	}
	
	reflex growth{
	if age_in_months >= 24{
	create (F_Awb) number:1 {
		location <-myself.location;
		age_in_months<- 24.0;

			}do die;
		}
	}

	aspect base {
		draw square(2) color:  #yellow;
	}
}

species F_Awb parent: SFW {
	reflex mortality {
	if flip(proba_die_F_Awb) {
		do die ;
		}
	}
	aspect base {
		draw square (3) color:  #yellow;
	}
}

species animal2 parent: animal{
	
	//resting and moving
	reflex manage_resting  {		
		if (resting) {//intercambiar con building
			need_to_rest <- (current_hour between(7,21)); //come_back_hour) or (current_hour < leaving_hour);
			resting <- need_to_rest;
		} else { need_to_rest <- (current_hour between(7,21));}//>= come_back_hour) ;}
	}	

	list<wia> reachable_feed ;//update: feeding_places where (each.food >= 0.5);
	list<wia> availa_f ;//update: reachable_feed at_distance detect_range;
	list<wia> availa_feed; 
	list<wia> visitados;
	
reflex noback {		
		reachable_feed <-(feeding_places  at_distance detect_range);
		availa_f <-reachable_feed where (each.food >= 0.2);
		if (not same_day){
		visitados <- visitados + current_target;		
		availa_feed<-availa_f-visitados;	
		}else{	
		visitados <- [];	}
 }
 
	reflex leave when: (not resting)  and (target = nil)  {
		float quantity_food;
		ask (feeding_places overlapping self ){
		quantity_food<- food;
		}
		if 	quantity_food <= 0.05{
		availa_feed <-availa_feed where (each.is_urban=false);

		current_target <- need_to_rest ? (resting_places closest_to self) : ( (availa_feed) closest_to self );			
		target <- any_location_in(current_target);	}	
		else if  need_to_rest {
		current_target <-(resting_places closest_to self);			
		target <- any_location_in(current_target);
		}
	}	

   	reflex moving when: target != nil {
		do goto target: target on: road_network;
		if (location = target) {
			target <- nil;
			if (need_to_rest and (current_target.type = "resting place")) {
				resting <- true;}
		}
	
	}	
	
	
	reflex feed when: !empty (feeding_places overlapping self){
      	ask feeding_places overlapping self {
      		food <- food - ((1000/(self.surface)));	
		}
		}
  aspect base {
		draw square(35) color: #magenta;
		
	}
	}	

//SubSpecies WW

species WM_Jwb parent: animal2 {
	
	reflex mortality {
	if flip(proba_die_M_Jwb) {
		do die ;
		}
	}
	
	reflex growth{
	if age_in_months >= 12{
	if flip (habit_prob){
		create (WM_Ywb) number:1 {
		location <- myself.location;
		age_in_months<- 12.0;

			}
		}do die;
		}
	}
	
	aspect base {
		draw square(1) color:  #lightblue;
	}
}

species WM_Ywb parent: animal2 {
	reflex mortality {
	if flip(proba_die_M_Ywb) {
		do die ;
		}
	}
	

	reflex growth{
	if age_in_months >= 24{
	create (WM_Awb) number:1 {
		location <-myself.location;
		age_in_months<- 24.0;

			}do die;
		}
	}
	
	
	aspect base {
		draw square(2) color:  #lightblue;
	}
}

species WM_Awb parent: animal2 {
	reflex mortality {
	if flip(proba_die_M_Awb) {
		do die ;
		}
	}
		
	aspect base {
		draw square(3) color:  #lightblue;
	}
}

species WF_Jwb parent: WFW {
	reflex mortality {
	if flip(proba_die_F_Jwb) {
		do die ;
		}
	}
	
	
	reflex growth{
	if age_in_months >= 12{
	if flip (habit_prob){
		create (F_Ywb) number:1 {
		location <- myself.location;
		age_in_months<- 12.0;

			}
		} else {
		create (WF_Ywb) number:1 {
		int age_month_init<-0;
		location <-myself.location;
		age_in_months<- 12.0;

			}
		}do die;
		}
	}

	aspect base {
		draw square(1) color:  #lightyellow;
	}
}

species WF_Ywb parent: WFW {
	reflex mortality {
	if flip(proba_die_F_Ywb) {
		do die ;
		}
	}
		
	reflex growth{
	if age_in_months >= 24{
	create (WF_Awb) number:1 {
		location <-myself.location;
		age_in_months<- 24.0;

			}do die;
		}
	}
	
	aspect base {
		draw square(2) color: #lightyellow;
	}
}

species WF_Awb parent: WFW {
	reflex mortality {
	if flip(proba_die_F_Awb) {
		do die ;
		}
	}
	
	aspect base {
		draw square (3) color:  #lightyellow;
	}
}	

	

species wia {
	  string type <- "wia";
	  string type2 <-"wia";
	  string humanUse <- "wia";
	  string urban <- "NO";
	  bool is_urban<-false;
	  float surface;
	  float minFood<-0.01;
      float maxFood ;
      float maxFoodU;
      float maxFoodN;
      float maxFoodS <- (maxFoodN /2);
      float foodProd ;
      float foodProdU <- rnd(0.009,0.04);//0.033;//0.016 para el 80% diario
      float foodProdN <-rnd(0.006,0.02);// 0.0104 ;//es el 15% diario //0.00209 ES 0.1(10%) ENTRE 48 STEPS DE 12 HORAS A 4 STEPS LA HORA (15 MIN)
      float foodProdS <- (foodProdN/ 2) ;
      float food<-0.9 min: 0.00 max: maxFood;
     float foodini;
	  bool growing_time <- false update: current_hour between(8,20);//<= 3 or current_month >= 11 ;
	 bool is_infected<-false;
	 bool is_susceptible<-true;


	  reflex grow when: growing_time {
	  	
	  	food<- food + foodProd ;
	  	
	  }
	  reflex control when:(current_hour<=1) and (current_daysim<=1) {
	  	if  food<=0.0{
	  		food<-rnd(0.2,0.8);
	  	}
	  	
	  }
	  
	  reflex is_urban {
	  	if (is_urban){
	  		foodProd <- foodProdU;
	  		maxFood<- maxFoodN;
	  	}else{
	  		foodProd <- foodProdN;
	  		if (scarce_period) {
      		maxFood<- maxFoodS;
      		foodProd <- (foodProdS);
      	}else{
      		maxFood<- maxFoodN;
      		foodProd <- (foodProdN);
      	}
	  	}
	  }
		
      rgb color <- rgb(int(255 * (1 - food)), 255, int(255 * (1 - food))) update: rgb(int(255 * (1 - food)), 255, int(255 * (1 - food))) ;
   
   aspect base {
		draw shape color: ((type = "resting place") ? #grey : ( (is_infected) ? #red :color));
	}
	}   

species building {
	  string type <- "building";
	  string district;
      
      
   
   aspect base {
		draw shape color:
	((type = "living place") ? #cyan : ((type = "working place") ? #blue : ((type = "health place") ? #salmon : #yellow ) )) border: #black;
	}
	}   
	
species people skills:[moving] {
	string type <- "people";
	string W_D;
	string R_D;
	float speedcar<-speed*5;
	building living_place <- nil ;
	building working_place <- nil ;
	int start_work ;
	int end_work  ;
	int start_natu;
	int end_natu;
	float outdoor_probability <- 0.332;
	float leissure_prob <- 0.332;
	float health_prob <- (1.0*calcul_year);
	string objective ; 
	point the_target <- nil ;
	float interaction_distance<- 10.0 #m;
	float incidence_distance<- 5.5 #m;
	float feeding_probability;
	float aggression_probability;
	float car_distance <-2000.0#m;
	int gravedad;
	int estancia;
	reflex doctor {
		if flip (health_prob) {
		gravedad <- rnd(1,10);
		estancia <- 0;
		objective<- "health";
		the_target <- any_location_in ((health_places) closest_to self); 
		
		}
	}
	reflex leave_doctor when: (objective = "health"){ 
		estancia<- estancia +1;
		if estancia >= gravedad{
		objective <- "resting" ;
		the_target <- any_location_in (living_place);
		}
	}
	
	reflex time_to_work when: (not is_weekend) and ((current_hour = start_work) and (objective = "resting")){
		objective <- "working" ;
		the_target <- any_location_in (working_place);}	
	
	reflex time_to_go_home when:  (not is_weekend) and ((current_hour = end_work and objective = "working")) {
		objective <- "resting" ;
		the_target <- any_location_in (living_place); } 
	
	reflex going_weekend when: (is_weekend) and ((current_hour = start_natu) and (objective = "resting" )) {
		objective <- "weekend" ;
		if flip (leissure_prob) {
		the_target <- any_location_in (one_of (leissure_places)); 
		}else if flip (outdoor_probability) {
		the_target <- any_location_in (one_of (feeding_places)); 
		}
		}
	
	reflex time_to_go_homeW when: (is_weekend) and ((current_hour = end_natu) and (objective = "weekend")){
		objective <- "resting" ;
		the_target <- any_location_in (living_place); 
	}
	reflex move when: the_target != nil {
		do goto target: the_target on: road_network ; 
		if ((self distance_to the_target) >= car_distance){
			speed <- speedcar;
		} else {
			speed<-speed;
		}
		
		if the_target = location {
			the_target <- nil ;}
	}
	action be_attacked{
		the_target <- any_location_in ((health_places) closest_to self);
				gravedad <- rnd(1,10);
				estancia <- 0;
				objective<- "health";
	}

	  aspect base{
	  	draw square (5)color:  #salmon;}
}

species feeder_citi parent: people{
	float aggression_probability_F<- 0.087;	
	
	reflex attackpeople when:!empty (ALLallS at_distance incidence_distance){
		nb_encounters <-nb_encounters + 1;
		ask (cell overlapping self) {
				HWI <- HWI + 1;
		}
			if flip (aggression_probability_F){
				do be_attacked;
				nb_agressions<-nb_agressions+1;
				ask (cell overlapping self) {
				wb_attacks <- wb_attacks + 1;
		}	
			}	
	}
	reflex feed_event when:!empty(all_toge at_distance incidence_distance){
		nb_encounters <-nb_encounters + 1;
		ask (cell overlapping self) {
				HWI <- HWI + 1;
		}
			if flip (feeding_probability){
				nb_feeding<-nb_feeding +1;
				ask (cell overlapping self) {
				wb_feed_events <- wb_feed_events + 1;
			}
				}	
	}
	float feeding_probability<- 0.37;

	aspect base {
		draw triangle(3) color:  #lime;}
}

species pet_owners parent: people{
	float aggression_probability_PO<- 0.038;
	reflex attackpeople when: !empty (ALLallS at_distance incidence_distance){
		nb_encounters <-nb_encounters + 1;
		ask (cell overlapping self) {
				HWI <- HWI + 1;
		}
			if flip (aggression_probability_PO){
				the_target <- any_location_in ((health_places) closest_to self);
				gravedad <- rnd(1,10);
				estancia <- 0;
				objective<- "health";
				nb_agressions<-nb_agressions+1;
				ask (cell overlapping self) {
				wb_attacks <- wb_attacks + 1;
		}
			}
	}
	
	
	aspect base {
		draw triangle(3) color:  #silver;}
}

species normal_citi parent: people{
	float aggression_probability_NC<- 0.013;
	reflex attackpeople when: !empty (ALLallS at_distance incidence_distance){
		nb_encounters <-nb_encounters + 1;
		ask (cell overlapping self) {
				HWI <- HWI + 1;
		}
			if flip (aggression_probability_NC){
				the_target <- any_location_in ((health_places) closest_to self);
				gravedad <- rnd(1,10);
				estancia <- 0;
				objective<- "health";
				nb_agressions<-nb_agressions+1;
				ask (cell overlapping self) {
				wb_attacks <- wb_attacks + 1;
		}
			}
	}
	
	aspect base {
		draw triangle(3) color:  #black;}
}

grid cell height: 100 width: 100 neighbors: 8{
	int wb_presence <- 0;
	int wb_attacks<-0;
	int wb_feed_events<-0;
	int HWI<-0;

	
	//color updated according to the wb_presence level (from red - high wb_presence to green - no wb_presence)
	rgb color <- #green;// update: rgb(255 *(wb_infection_events/30.0) , 255 * (1 - (wb_infection_events/30.0)), 0.0);
}





experiment prototypeINI type:gui {
  
	output {
		
		display map type:opengl{
			//grid cell elevation: wb_presence * 3.0 triangulation: true transparency: 0.9;
			species wia aspect: base;
			species building aspect: base refresh: false;
			species road aspect: base refresh: false;
			event 'r' action:store;
			event 's' action: saveroad;
			species F_Jwb aspect: base ;
			species M_Jwb aspect: base ;
			species M_Ywb aspect: base ;
			species F_Ywb aspect: base ;
			species F_Awb aspect: base ;
			species M_Awb aspect: base ;
			species WF_Jwb aspect: base ;
			species WM_Jwb aspect: base ;
			species WM_Ywb aspect: base ;
			species WF_Ywb aspect: base ;
			species WF_Awb aspect: base ;
			species WM_Awb aspect: base ;
			//species carcass aspect: base ;
			//species people aspect: base;
			
//			species feeder_citi aspect: base;
//		    species normal_citi aspect: base;
//			species pet_owners aspect: base;
					}
		
		
	
			display WILD_BOAR2 refresh: every(168 # cycles){//CADA semana
			chart "WB POPULATION DYNAMICS" type: series
			{
	data "number_of_Males_juveniles" value: nb_M_Jwb color: #lightgrey ;
		data "number_of_Females_juveniles" value: nb_F_Jwb color: #yellow ;
		data "number_of_Males_yearlings" value: nb_M_Ywb color: #darkgrey ;
		data "number_of_Females_yearlings" value: nb_F_Ywb color: #orange ;
		data "number_of_Males_adults" value: nb_M_Awb color: #black ;
		data "number_of_Females_adults" value: nb_F_Awb color: #red ;
		data "number_of_WMales_juveniles" value: nb_WM_Jwb color: #lightgrey ;
		data "number_of_WFemales_juveniles" value: nb_WF_Jwb color: #yellow ;
		data "number_of_WMales_yearlings" value: nb_WM_Ywb color: #darkgrey ;
		data "number_of_WFemales_yearlings" value: nb_WF_Ywb color: #orange ;
		data "number_of_WMales_adults" value: nb_WM_Awb color: #black ;
		data "number_of_WFemales_adults" value: nb_WF_Awb color: #red ;
			}
			}
			display WILD_BOAR refresh: every(24 # cycles){//CADA DIA
			chart "WB POPULATION DYNAMICS" type: series
			{
	data "number_of_Males_juveniles" value: nb_M_Jwb color: #lightgrey ;
		data "number_of_Females_juveniles" value: nb_F_Jwb color: #yellow ;
		data "number_of_Males_yearlings" value: nb_M_Ywb color: #darkgrey ;
		data "number_of_Females_yearlings" value: nb_F_Ywb color: #orange ;
		data "number_of_Males_adults" value: nb_M_Awb color: #black ;
		data "number_of_Females_adults" value: nb_F_Awb color: #red ;
		data "number_of_WMales_juveniles" value: nb_WM_Jwb color: #lightgrey ;
		data "number_of_WFemales_juveniles" value: nb_WF_Jwb color: #yellow ;
		data "number_of_WMales_yearlings" value: nb_WM_Ywb color: #darkgrey ;
		data "number_of_WFemales_yearlings" value: nb_WF_Ywb color: #orange ;
		data "number_of_WMales_adults" value: nb_WM_Awb color: #black ;
		data "number_of_WFemales_adults" value: nb_WF_Awb color: #red ;
			}
			}
	
		monitor "Date" value: current_date;
		monitor "number_of_Human_Wb_enco" value: nb_encounters color: #black;
		monitor "number_of_attack_events" value: nb_agressions color: #black;
		monitor "number_of_feeding_events" value: nb_feeding color: #black;
		monitor "number_of_Males_juveniles" value: nb_M_Jwb color: #lightgrey ;
		monitor "number_of_Females_juveniles" value: nb_F_Jwb color: #yellow ;
		monitor "number_of_Males_yearlings" value: nb_M_Ywb color: #darkgrey ;
		monitor "number_of_Females_yearlings" value: nb_F_Ywb color: #orange ;
		monitor "number_of_Males_adults" value: nb_M_Awb color: #black ;
		monitor "number_of_Females_adults" value: nb_F_Awb color: #red ;
		monitor "number_of_WMales_juveniles" value: nb_WM_Jwb color: #lightgrey ;
		monitor "number_of_WFemales_juveniles" value: nb_WF_Jwb color: #yellow ;
		monitor "number_of_WMales_yearlings" value: nb_WM_Ywb color: #darkgrey ;
		monitor "number_of_WFemales_yearlings" value: nb_WF_Ywb color: #orange ;
		monitor "number_of_WMales_adults" value: nb_WM_Awb color: #black ;
		monitor "number_of_WFemales_adults" value: nb_WF_Awb color: #red ;
		monitor "number_of_HWIs" value: nb_interactions color: #black;
		monitor "number_of_feedingk_events" value: nb_feed_events color: #black;
		monitor "number_of_attacking_events" value: nb_attacks color: #black;
		
	}
}
