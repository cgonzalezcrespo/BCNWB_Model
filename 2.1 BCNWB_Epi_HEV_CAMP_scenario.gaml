/***
* Name: BCNWB-Epi AMR-CAMP & HEV
* Author: cgonzalez
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model BCNWB_epi_AMRCAMP_HEV

/* Antimicrobial-resistant Campylobacter and Hepatities E virus scenarios */
global {
	//FILES
	date starting_date <- date([2020,10,1,0,0,0]);
	file building_shapefile <- file("../includes/BUILDEFINI.shp");
	file wia_shapefile <- file("../includes/WIACNP.shp");
	file road_shapefile <- file("../includes/ROADDEF.shp");
	file initial_wwb <- file("../includes/iniciowwb.shp");
	file initial_swb <- file("../includes/CB.shp");
	geometry shape <- envelope(road_shapefile);
	graph road_network;
	graph road_networkC;
	graph road_network2;
	graph road_network4;
	
	//TIME
	float step <- 60 #mn;
	float calcul_day<- ((1/24));//for daily calculations
	float calcul_month<-((1/30)*calcul_day);//for monthly calculations
	float calcul_year<-((1/365)*calcul_day);//for yearly calculations
	bool same_day<- false update: current_hour between(8,20);
	bool is_weekend<- false update: current_day >=5;
	int current_hour update: int (time / #hour) mod 24; 
	int current_month update: int (time / #month) mod 12 min: 1;
	int current_week update: int (time / #week) mod 4 min: 1;
	int current_day update: int (time / #day) mod 7 min: 1;
	int current_daysim update: int (time / #day) mod 365 min: 1;
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
	
	//Epidemiology values
	float transmission_range <- 0.5#m;
	float prevalence<-0.0; //AMR-CAMP: 0.6; HEV: 0.2;
	float exposition<-0.3;
	float expuinitial<-0.01;

	float init_INFW<-348*prevalence;
	float init_INFS<-293*prevalence;
	
	float init_Patrisk<-nb_people*0.2;
	//float exposed_rate;

	//Rate for the infection success 
	float beta_wp <- 0.25 ;//creation of Environmental Source-feces
	float beta_z <- 0.0;//proba_spread zoonotic (AMR-CAMP: 0.0116; HEV: 0.01375)
	
	//Pathogen survival in the environment
	float patho_surv<-5.00;
	//distance where feces will be removed faster-related with distance to buildings
	float feces_diastance<-300#m;
    
	list<animal1> all_toge;
	list<animal1> INF_SW;
	list<animal2> all_toge2;
	list<animal2> INF_WW;
	list<animal> ALLall;
	list<animal>ALLallS;
	list<people>PeEverExposed update: agents of_generic_species people where each.ever_exposed;
	list<people>Pe_atRisk_EverExposed;
	list<people> PeopleS;
	list<people> PeopleI;
	list<people> PeopleE;
	list<people> PeopleR;
	list<people> PeopleRisk;
	int wb_infected;
	int	nb_wb_not_infected;
    float infected_rate; 

reflex update_values{	
		all_toge<-  (agents of_generic_species animal1 );
		all_toge2<-  (agents of_generic_species animal2);
		ALLall <-all_toge+all_toge2;
		ALLallS <-((agents of_generic_species animal1) where each.agressive_state) ;
		INF_SW<-agents of_generic_species animal1 where each.is_infected;
		INF_WW<-agents of_generic_species animal2 where each.is_infected;
	}
	
	reflex update_rates{
		wb_infected<- (nb_INF_SW+nb_INF_WW);
		nb_wb_not_infected<-nb_all- wb_infected;
		infected_rate<-wb_infected/nb_all;
	}
	
	
	reflex update_peoplenbs{
		PeEverExposed<-agents of_generic_species people where each.ever_exposed;
		Pe_atRisk_EverExposed<- PeEverExposed where each.is_atrisk;
		PeopleRisk<- agents of_generic_species people where each.is_atrisk;
		PeopleS<-agents of_generic_species people where each.is_susceptible;
		PeopleE<-agents of_generic_species people where each.is_exposed;
		PeopleI<-agents of_generic_species people where each.is_infected;
		PeopleR<-agents of_generic_species people where each.is_resistant;
	}
	int nb_people_risk->{length (PeopleRisk)};
	int nb_people_Risk_exp->{length (Pe_atRisk_EverExposed)};
	int nb_people_exp->{length (PeEverExposed)};
	int nb_INF_SW->{length (INF_SW)};
	int nb_INF_WW->{length (INF_WW)};
	int nb_PeopleS->{length (PeopleS)};
	int nb_PeopleE->{length (PeopleE)};
	int nb_PeopleI->{length (PeopleI)};
	int nb_PeopleR->{length (PeopleR)};
	int nb_People->{length (people)};
	int nb_all_wb -> {length (all_toge)};
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

	
	action saveroad{
		save cell to:"../results/ARCBNO.shp" type:"shp" attributes: ["ID":: int(self),"wb_infection_events"::(wb_infection_events),
		"wbtoenv_infection_events"::(wbtoenv_infection_events),"envtowb_infection_events"::(envtowb_infection_events),
		"envtocz_infection_events"::(envtocz_infection_events),"feces_events"::(feces_events)];//
}
	reflex end_simulation when: (current_daysim >=366) or (nb_all = 0) {
		do pause;
		//save road to:"../results/roadtest20.shp" type:"shp" attributes: ["ID":: int(self),"usedbywb":: (usedbywb), "NATURE":: (USE),"TYPE":: string(TYPE) ];
		save cell to:"../results/ARCB2.shp" type:"shp" attributes: ["ID":: int(self),"wb_infection_events"::(wb_infection_events),
		"wbtoenv_infection_events"::(wbtoenv_infection_events),"envtowb_infection_events"::(envtowb_infection_events),
		"envtocz_infection_events"::(envtocz_infection_events),"feces_events"::(feces_events)];
	}
	
	reflex stochasticity when: (current_daysim = 1){
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
		 
	//Initialization of the building using the shapefile of buildings
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
	road_network2 <- as_edge_graph(road where(each.TYPE = "urban"));
	road_network4 <- as_edge_graph(road where(each.TYPE = "camino"));
	road_networkC <- as_edge_graph(road_network2+road_network4);	
create feeder_citi from: csv_file("../includes/ALIM.csv", true) with: [W_D::string(get ("W_D")), R_D::string(read ("R_D"))] {
	    	speed <- min_speed + rnd (max_speed - min_speed) ;
			start_work <- min_work_start + rnd (max_work_start - min_work_start) ;
			end_work <- min_work_end + rnd (max_work_end - min_work_end) ;
			start_natu <- min_natu_start + rnd (max_natu_start - min_natu_start);
			end_natu <- min_natu_end + rnd (max_natu_end - min_natu_end) ;
			living_place<- one_of(living_places where (each.district= R_D)) ;
			working_place <- one_of(working_places where (each.district= W_D)) ;
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
			objective <- "resting";
			location <- any_location_in (living_place); } 	    
		
		ask (7765) among (normal_citi){
				is_atrisk<-true;
			}	
			ask (3329) among (pet_owners){
				is_atrisk<-true;
			}
			ask (372) among (feeder_citi){
				is_atrisk<-true;
			}

//Creation of the Swb agents	  
 		create M_Jwb number: nb_M_Jwb_init{
			location <- any_location_in(one_of(initlocs));
			speed <- rnd(1.0,5.0) #km/#h;
			age_in_months<- rnd(5.0,10.0);
			is_infected <- false;
      		}
      	create F_Jwb number: nb_F_Jwb_init{
			location <- any_location_in(one_of(initlocs));
			speed <- rnd(1.0,5.0) #km/#h;
			age_in_months<- rnd(5.0,10.0);
			is_infected <- false;
      		}
      	create M_Ywb number: nb_M_Ywb_init{
			location <- any_location_in(one_of(initlocs));
			speed <- rnd(3.0,7.0) #km/#h;
			age_in_months<- rnd(15.0,20.0);
			is_infected <- false;
      		}
      	create F_Ywb number: nb_F_Ywb_init{
			location <- any_location_in(one_of(initlocs));
			speed <- rnd(3.0,7.0) #km/#h;
			age_in_months<- rnd(15.0,20.0);		
			is_infected <- false;	
      		}
      		
      		ask (nb_F_Ywb_init*0.1) among F_Ywb{
			pregnant <- true;
			contador_pregnant<-rnd(10,2800);
			}
		
      	create M_Awb number: nb_M_Awb_init{
			location <- any_location_in(one_of(initlocs));
			age_in_months<- rnd(24.0,80.0);
			is_infected <- false;
      		}
     	create F_Awb number: nb_F_Awb_init{
			location <- any_location_in(one_of(initlocs));
			age_in_months<- rnd(24.0,80.0);
			is_infected <- false;
      		}
			
			ask (nb_F_Awb_init*0.3) among F_Awb{
			pregnant <- true;
			contador_pregnant<-rnd(10,2800);
			}
			
//Creation of the Wwb agents	  
 		create WM_Jwb number: nb_WM_Jwb_init{
			location <- any_location_in(one_of(initlocw));
			speed <- rnd(1.0,5.0) #km/#h;
			age_in_months<- rnd(5.0,10.0);
			is_infected <- false;
      		}
      	create WF_Jwb number: nb_WF_Jwb_init{
			location <- any_location_in(one_of(initlocw));
			speed <- rnd(1.0,5.0) #km/#h;
			age_in_months<- rnd(5.0,10.0);
			is_infected <- false;
      		}
      	create WM_Ywb number: nb_WM_Ywb_init{
			location <- any_location_in(one_of(initlocw));
			speed <- rnd(3.0,7.0) #km/#h;
			age_in_months<- rnd(15.0,20.0);
			is_infected <- false;
      		}
      	create WF_Ywb number: nb_WF_Ywb_init{
			location <- any_location_in(one_of(initlocw));
			speed <- rnd(3.0,7.0) #km/#h;
			age_in_months<- rnd(15.0,20.0);	
			is_infected <- false;	
      		}
      		ask (nb_WF_Ywb_init*0.1) among WF_Ywb{
			pregnant <- true;
			contador_pregnant<-rnd(10,2800);
			}
      		
      	create WM_Awb number: nb_WM_Awb_init{
			location <- any_location_in(one_of(initlocw));
			age_in_months<- rnd(24.0,80.0);
			is_infected <- false;
      		}
     	create WF_Awb number: nb_WF_Awb_init{
			location <- any_location_in(one_of(initlocw));
			age_in_months<- rnd(24.0,80.0);
			is_infected <- false;
      		}
			ask (nb_WF_Awb_init*0.3) among WF_Awb{
			pregnant <- true;
			contador_pregnant<-rnd(10,2800);
			}	
			
			//init_exp	
			ask (init_INFW) among  (WF_Awb+WF_Ywb+WF_Jwb+WM_Awb+WM_Ywb+WM_Jwb){
			is_infected <- true;
			}
			
			ask (init_INFS) among  (F_Awb+F_Ywb+F_Jwb+M_Awb+M_Ywb+M_Jwb){
			is_infected <- true;
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
	float speed;
	float age_in_months;
	point target;
	wia current_target;
	float detect_range<-1000#m;
	bool resting <- true ;
	bool need_to_rest <- true ;
	bool pregnant<- false;
	float incidence_distance<- 10.5#m;
	bool is_infected<-false;
	
	reflex Create_Feces when: is_infected{
		if flip (beta_wp){
			create (feces)  {
			location <- myself.location ; //
			if (!empty (building at_distance feces_diastance)){
				in_urban_area<-true;
			}
			ask (cell overlapping self){
					feces_events<-feces_events+1;
				}
		}
		}
	}
	
	reflex aging {
			age_in_months <- age_in_months + 0.00137;
			if age_in_months >= 132{
	do die;
		}
	}	
}

species feces {
bool is_infected<-true;
bool in_urban_area<-false;

reflex infectP when:(in_urban_area and (!empty (PeopleS at_distance transmission_range))){//at_distance transmission_range
			ask (PeopleS) at_distance transmission_range	{
				if is_atrisk{
					
					if flip(beta_z*0.5){
			is_susceptible<-false;
			is_exposed<-true;
			is_infected <- false;
			is_resistant<-false;
			ever_exposed <-true;
				ask (cell overlapping self){
					envtocz_infection_events<-envtocz_infection_events+1;
				}
			}else{
				is_susceptible<-true;
			is_exposed<-false;
			is_infected <- false;
			is_resistant<-false;
			}
				}else{
					
					if flip(beta_z){
			is_susceptible<-false;
			is_exposed<-true;
			is_infected <- false;
			is_resistant<-false;
			ever_exposed <-true;
				ask (cell overlapping self){
					envtocz_infection_events<-envtocz_infection_events+1;
					//feces_infection_events<-feces_infection_events+1;
				}
			}else {
			is_susceptible<-true;
			is_exposed<-false;
			is_infected <- false;
			is_resistant<-false;
			}
				}
		}

	}


float conta_feces<-0.0;
reflex shallDie {
	conta_feces<-conta_feces+calcul_day;
	
	if (in_urban_area) {
		if conta_feces >=1.5{
			do die;
		}
	}else if (conta_feces>=patho_surv){
		do die;}
  }
  aspect base {
		draw square(1) color:  #red ;
	}
}

species animal1 parent: animal{

	bool agressive_state <- false;
	float agressive_prob<- (0.053*calcul_year);
	
	reflex speed_people {
		ask normal_citi at_distance incidence_distance{
			speed<-max_speed;
		}
		ask pet_owners at_distance incidence_distance{
			speed<-max_speed;
		}
		ask feeder_citi at_distance incidence_distance{
			speed<-min_speed;
		}
	}
	
	//resting and moving
	reflex manage_resting  {		
		if (resting) {
			need_to_rest <- (current_hour between(8,20));
			resting <- need_to_rest;
		} else { need_to_rest <- (current_hour between(8,20));}
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
		draw square(4) color: (is_infected) ? #red : #blue;
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
		draw square(6) color: (is_infected) ? #red : #blue;
	}
}

species M_Awb parent: animal1 {
	reflex mortality {
	if flip(proba_die_M_Awb) {
		do die ;
		}
	}
	
	aspect base {
		draw square(9) color: (is_infected) ? #red : #blue;
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
		draw square(4) color: (is_infected) ? #red : #yellow;
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
		draw square(6) color: (is_infected) ? #red : #yellow;
	}
}

species F_Awb parent: SFW {
	reflex mortality {
	if flip(proba_die_F_Awb) {
		do die ;
		}
	}
	aspect base {
		draw square (9) color: (is_infected) ? #red : #yellow;
	}
}

species animal2 parent: animal{
	
	//resting and moving
	reflex manage_resting  {		
		if (resting) {
			need_to_rest <- (current_hour between(8,20)); 
			resting <- need_to_rest;
		} else { need_to_rest <- (current_hour between(8,20));}
	}	

	list<wia> reachable_feed ;
	list<wia> availa_f ;
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
		create (M_Ywb) number:1 {
		location <- myself.location;
		age_in_months<- 12.0;
			}
		} else {
		create (WM_Ywb) number:1 {
		int age_month_init<-0;
		location <-myself.location;
		age_in_months<- 12.0;

			}
		}do die;
		}
	}
	
	aspect base {
		draw square(4) color: (is_infected) ? #red : #lightblue;
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
	create (M_Awb) number:1 {
		location <-myself.location;
		age_in_months<- 24.0;

			}do die;
		}
	}
	
	
	aspect base {
		draw square(6) color: (is_infected) ? #red : #lightblue;
	}
}

species WM_Awb parent: animal2 {
	reflex mortality {
	if flip(proba_die_M_Awb) {
		do die ;
		}
	}
		
	aspect base {
		draw square(9) color: (is_infected) ? #red : #lightblue;
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
		draw square(4) color: (is_infected) ? #red : #lightyellow;
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
	create (F_Awb) number:1 {
		location <-myself.location;
		age_in_months<- 24.0;

			}do die;
		}
	}
	
	aspect base {
		draw square(6) color: (is_infected) ? #red : #lightyellow;
	}
}

species WF_Awb parent: WFW {
	reflex mortality {
	if flip(proba_die_F_Awb) {
		do die ;
		}
	}
	
	aspect base {
		draw square (9) color: (is_infected) ? #red : #lightyellow;
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
      float foodProdU <- rnd(0.009,0.04);
      float foodProdN <-rnd(0.006,0.02);
      float foodProdS <- (foodProdN/ 2) ;
      float food<-0.9 min: 0.00 max: maxFood;
      float foodini;
	  bool growing_time <- false update: current_hour between(8,20);
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
	float interaction_distance<- 15.5#m;
	float incidence_distance<- 5.5 #m;
	float feeding_probability;
	float aggression_probability;	
	float car_distance <-2000.0#m;
	bool is_susceptible<-true;
	bool is_exposed<-false;
	bool is_infected <- false;
	bool is_resistant<-false;
	bool is_atrisk<-false;
	bool ever_exposed<-false;
	float contadorincu <- 0.0;
	
	int gravedad;
	int estancia;
	
	action be_attacked{
		the_target <- any_location_in ((health_places) closest_to self);
				gravedad <- rnd(1,10);
				estancia <- 0;
				objective<- "health";
	}
	
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
		do goto target: the_target on: road_networkC; 
		if ((self distance_to the_target) >= car_distance){
			speed <- speedcar;
		} else {
			speed<-speed;
		}
		
		if the_target = location {
			the_target <- nil ;}
	}


	  aspect base{
	  	draw square (5)color: (is_infected) ? #red : #salmon;}
}

species feeder_citi parent: people{
	float aggression_probability_F<- 0.087;	
	reflex attackpeople when:!empty (ALLallS at_distance incidence_distance){
			if flip (aggression_probability_F){
				do be_attacked;
				
			}	
	}
	reflex feed_event when:!empty(all_toge at_distance incidence_distance){
		
				
	}
	float feeding_probability<- 0.37;

	aspect base {
		draw triangle(3) color:  #lime;}
}

species pet_owners parent: people{
	float aggression_probability_PO<- 0.038;
	reflex attackpeople when: !empty (ALLallS at_distance incidence_distance){
		
			if flip (aggression_probability_PO){
				the_target <- any_location_in ((health_places) closest_to self);
				gravedad <- rnd(1,10);
				estancia <- 0;
				objective<- "health";
				
			}
	}
	
	
	aspect base {
		draw triangle(3) color:  #silver;}
}

species normal_citi parent: people{
	float aggression_probability_NC<- 0.013;
	reflex attackpeople when: !empty (ALLallS at_distance incidence_distance){
		
			if flip (aggression_probability_NC){
				the_target <- any_location_in ((health_places) closest_to self);
				gravedad <- rnd(1,10);
				estancia <- 0;
				objective<- "health";
			}
	}
	
	aspect base {
		draw triangle(3) color:  #black;}
}

grid cell height: 100 width: 100 neighbors: 8{
	int feces_events<-0;
	int wb_infection_events<-0;
	int wbtowb_infection_events<-0;
	int wbtoenv_infection_events<-0;
	int envtowb_infection_events<-0;
	int envtocz_infection_events<-0;
	
	rgb color <- #green;
	}


experiment AMRCAMP_HEV type:gui {
	output {
		
		display map type:opengl{
			species wia aspect: base;
			species building aspect: base refresh: false;
			species road aspect: base refresh: false;
			
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
			species feces aspect: base ;
			species feeder_citi aspect: base;
		    species normal_citi aspect: base;
			species pet_owners aspect: base;
					}
		
				display PEOPLE refresh: every(48 # cycles){//CADA DIA
			chart "Disease spreading CB" type: series
			{
		data "EXPOSED People" value: nb_PeopleE color: #orange;
		data "INFECTED People" value: nb_PeopleI color: #red;
			}
			}
			display WILD_BOAR refresh: every(48 # cycles){//CADA DIA
			chart "Disease spreading CB" type: series
			{
		data "INFECTED SWB" value: nb_INF_SW color: #red;
		data "INFECTED WWB" value: nb_INF_WW color: #magenta;
			}
			}
			
			display PEOPLE2 refresh: every(336 # cycles){
			chart "Disease spreading CB" type: series
			{
		data "EXPOSED People" value: nb_PeopleE color: #orange;
		data "INFECTED People" value: nb_PeopleI color: #red;
		data "RESISTANT People" value: nb_PeopleR color: #midnightblue;
			}
			}
			display WILD_BOAR2 refresh: every(336 # cycles){//CADA DIA
			chart "Disease spreading CB" type: series
			{
		data "INFECTED SWB" value: nb_INF_SW color: #red;
		data "INFECTED WWB" value: nb_INF_WW color: #magenta;
			}
			}
			
	
		monitor "Date" value: current_date;
		monitor "number_wb_infected" value: wb_infected color: #black ;
		monitor "People_ever_exposed" value: nb_people_exp color: #black ;
		monitor "People_Risk_ever_exposed" value: nb_people_Risk_exp color: #black ;
		monitor "number_wb_not_infected" value: nb_wb_not_infected color: #black ;
		monitor "infected_rate" value: infected_rate color: #black ;
		monitor "number_of_SWB" value: nb_all_wb color: #black ;
		monitor "number_of_WWB" value: nb_Wall_wb color: #black ;
		monitor "risk People" value: nb_people_risk color: #darkorange;
		monitor "INFECTED SWB" value: nb_INF_SW color: #red;
		monitor "INFECTED WWB" value: nb_INF_WW color: #magenta;
		monitor "SUSCEPTIBLE People" value: nb_PeopleS color: #yellow;
		monitor "EXPOSED People" value: nb_PeopleE color: #orange;
		monitor "INFECTED People" value: nb_PeopleI color: #red;

	}
}