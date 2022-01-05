/**
* Name: BCNWB-Epi AFSV
* Based on the internal empty template. 
* Author: cgonzalez
* Tags: 
*/


model BCNWB_Epi_AFSV

/* African swine fever scenario */

global {
	//FILES
	date starting_date <- date([2020,1,1,1,0,0]);
	file building_shapefile <- file("../includes/BUILDEFINI.shp");
	file wia_shapefile <- file("../includes/WIACNP.shp");
	file road_shapefile <- file("../includes/ROADDEF.shp");
	file initial_wwb <- file("../includes/iniciowwb.shp");
	file initial_swb <- file("../includes/inci2019.shp");
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
	int nb_M_Awb_init<- 22;//120;105
	int nb_F_Awb_init<- 23;//120;105
	int nb_M_Ywb_init<- 32;//220;190
	int nb_F_Ywb_init<- 35;//220;190
	int nb_M_Jwb_init<- 90;//320;275
	int nb_F_Jwb_init<- 91;//320;275
	//Abundances WWB
	int nb_WM_Awb_init<- 26;//105;
	int nb_WF_Awb_init<- 27;//105;
	int nb_WM_Ywb_init<- 39;//190;
	int nb_WF_Ywb_init<- 42;//190;
	int nb_WM_Jwb_init<- 106;//275;
	int nb_WF_Jwb_init<- 108;//275;
	
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
	float transmission_range <- 5#m;
	float transmission_rangeB <- 300#m;
	//int nb_people_infected <- 0 update: (animal1 + animal2) where (each.is_infected);
	//Rate for the infection success 
	float beta_ww <- 0.99 ;//proba_spread wb-wb
	float beta_wp <- 0.99 ;//proba_spread wb-place 0.08
	//Mortality rate for the host
	float nu <-  ((0.99/5)* calcul_day);
	//Rate for resistance 
	float delta <- 0.05;
	//Incubation 
	float incub_period<-10.00;//10 dias para ASFV
	//Pathogen survival in the environment
	float patho_surv<-56.00;//56 dias son 2 meses de 28 (8 semanas)
	//distance where carcass will be removed faster-related with distance to buildings
	float carcass_diastance<-300#m;
  
    //int nb_infected-> {length (all_toge count (each.is_infected))};
	//int nb_infected2-> {length (all_toge2 count (each.is_infected))};
	//int wb_infected;//-> (all_toge where (each.is_infected))+(all_toge2 where (each.is_infected));
    //int nb_wb_not_infected;// <- nb_all update: nb_all - wb_infected;
	//int nbinf -> {length (all_toge)};
	//int nbinf2 -> {length (all_toge2)};
	//int nbinf-> { (animal1) count (each.is_infected)};
	//int nbinf2-> { (animal2) count (each.is_infected)};
 	int nbinfwia-> { (wia) count (each.is_infected)};
	//int wb_infected update:nbinf+nbinf2;
	list<animal1> all_toge;
	list<animal1> SUS_SW;
	list<animal1> EXP_SW;
	list<animal1> INF_SW;
	list<animal1> RES_SW;
	list<animal2> all_toge2;
	list<animal2> SUS_WW;
	list<animal2> EXP_WW;
	list<animal2> INF_WW;
	list<animal2> RES_WW;
	//list<animal> all_wb;
//	list<animal> all_wbS;
	list<animal> ALLall;
	list<animal>ALLallS;
	int wb_infected;//<- (nb_INF_SW+nb_INF_WW);
	int	nb_wb_not_infected;//<- 0 update:(nb_SUS_SW+nb_SUS_WW+nb_RES_SW+nb_RES_SW);
    float infected_rate;// update: wb_infected/nb_all;
//	data "SUSCEPTIBLE SWB" value: all_toge count (each.is_susceptible) color: #green;
//		data "SUSCEPTIBLE WWB" value: all_toge2 count (each.is_susceptible) color: #green;
//		
//		data "EXPOSED SWB" value: all_toge count (each.is_exposed) color: #blue;
//		data "EXPOSED WWB" value: all_toge2 count (each.is_exposed) color: #blue;
//		data "INFECTED SWB" value: all_toge count (each.is_infected) color: #red;
//		data "INFECTED WWB" value: all_toge2 count (each.is_infected) color: #red;

reflex update_values{	
		all_toge<-  (agents of_generic_species animal1 );
		all_toge2<-  (agents of_generic_species animal2);
		ALLall <-agents of_generic_species animal;
		ALLallS <-agents of_generic_species animal where each.is_susceptible;//(all_toge+all_toge2);// where each.is_susceptible;
		SUS_SW<-agents of_generic_species animal1 where each.is_susceptible;
		SUS_WW<-agents of_generic_species animal2 where each.is_susceptible;
		EXP_SW<-agents of_generic_species animal1 where each.is_exposed;
		EXP_WW<-agents of_generic_species animal2 where each.is_exposed;
		INF_SW<-agents of_generic_species animal1 where each.is_infected;
		INF_WW<-agents of_generic_species animal2 where each.is_infected;
		RES_SW<-agents of_generic_species animal1 of_generic_species animal1 where each.is_resistant;
		RES_WW<-agents of_generic_species animal2 where each.is_resistant;
		wb_infected<- (nb_INF_SW+nb_INF_WW);
		nb_wb_not_infected<- (nb_SUS_SW+nb_SUS_WW+nb_RES_SW+nb_RES_SW);
		infected_rate<-wb_infected/nb_all;
	}
	
	int nb_SUS_SW->{length (SUS_SW)};
	int nb_SUS_WW->{length (SUS_WW)};
	int nb_EXP_SW->{length (EXP_SW)};
	int nb_EXP_WW->{length (EXP_WW)};
	int nb_INF_SW->{length (INF_SW)};
	int nb_INF_WW->{length (INF_WW)};
	int nb_RES_SW->{length (RES_SW)};
	int nb_RES_WW->{length (RES_WW)};
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

	

	action saveroad{
		save cell to:"../results/ASFV2.shp" type:"shp" attributes: ["ID":: int(self),"wb_presence":: (wb_presence), 
		"wb_attacks"::(wb_attacks), "wb_feed_events"::(wb_feed_events),"wb_infection_events"::(wb_infection_events),
		"wbtoenv_infection_events"::(wbtoenv_infection_events),"envtowb_infection_events"::(envtowb_infection_events),
		"carcass_infection_events"::(carcass_infection_events)];
}
	reflex end_simulation when: (current_daysim >=366) or (nb_all = 0) {
		do pause;
		//save road to:"../results/roadtest20.shp" type:"shp" attributes: ["ID":: int(self),"usedbywb":: (usedbywb), "NATURE":: (USE),"TYPE":: string(TYPE) ];
		save cell to:"../results/ASVF1.shp" type:"shp" attributes: ["ID":: int(self),"wb_presence":: (wb_presence), 
		"wb_attacks"::(wb_attacks), "wb_feed_events"::(wb_feed_events),"wb_infection_events"::(wb_infection_events),
		"wbtoenv_infection_events"::(wbtoenv_infection_events),"envtowb_infection_events"::(envtowb_infection_events),
		"carcass_infection_events"::(carcass_infection_events)];
	}
	
	reflex end_simulation2 when: ( ((nb_INF_SW+nb_INF_WW+nb_EXP_SW+nb_EXP_WW) = 0)) {
		if (current_day>3) and (nbinfwia =0) {
			do pause;
		//save road to:"../results/roadtest20.shp" type:"shp" attributes: ["ID":: int(self),"usedbywb":: (usedbywb), "NATURE":: (USE),"TYPE":: string(TYPE) ];
		save cell to:"../results/ASVFNO.shp" type:"shp" attributes: ["ID":: int(self),"wb_presence":: (wb_presence), 
		"wb_attacks"::(wb_attacks), "wb_feed_events"::(wb_feed_events),"wb_infection_events"::(wb_infection_events),
		"wbtoenv_infection_events"::(wbtoenv_infection_events),"envtowb_infection_events"::(envtowb_infection_events),
		"carcass_infection_events"::(carcass_infection_events)];
		}
		
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
	 contador_EV<-contador_EV+0.7292;
	 if (contador_EV >=365) {
	 	annual_EV <- rnd(-0.15,0.15);
	 	 contador_EV<-0.0;
	 }
	}
	

	
	float R0 ;
	
	init {
		
		 R0 <- (beta_ww)/(delta+nu);	
		 write "Basic Reproduction Number: "+ R0;
		 
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
			speed <- rnd(1.0,5.0) #km/#h;
			age_in_months<- rnd(5.0,10.0);
			is_susceptible<-true;
			is_exposed<-false;
			is_infected <- false;
			is_resistant<-false;
      		}
      	create F_Jwb number: nb_F_Jwb_init{
			location <- any_location_in(one_of(initlocs));
			speed <- rnd(1.0,5.0) #km/#h;
			age_in_months<- rnd(5.0,10.0);
			is_susceptible<-true;
			is_exposed<-false;
			is_infected <- false;
			is_resistant<-false;
      		}
      	create M_Ywb number: nb_M_Ywb_init{
			location <- any_location_in(one_of(initlocs));
			speed <- rnd(3.0,7.0) #km/#h;
			age_in_months<- rnd(15.0,20.0);
			is_susceptible<-true;
			is_exposed<-false;
			is_infected <- false;
			is_resistant<-false;
      		}
      	create F_Ywb number: nb_F_Ywb_init{
			location <- any_location_in(one_of(initlocs));
			speed <- rnd(3.0,7.0) #km/#h;
			age_in_months<- rnd(15.0,20.0);		
			is_susceptible<-true;
			is_exposed<-false;
			is_infected <- false;
			is_resistant<-false;	
      		}
      		
      		ask (nb_F_Ywb_init*0.1) among F_Ywb{
			pregnant <- true;
				contador_pregnant<-rnd(10,2800);
			}
		
      	create M_Awb number: nb_M_Awb_init{
			location <- any_location_in(one_of(initlocs));
			speed <- rnd(6.0,10.0) #km/#h;
			age_in_months<- rnd(24.0,80.0);
			is_susceptible<-true;
			is_exposed<-false;
			is_infected <- false;
			is_resistant<-false;
      		}
     	create F_Awb number: nb_F_Awb_init{
			location <- any_location_in(one_of(initlocs));
			speed <- rnd(6.0,10.0) #km/#h;
			age_in_months<- rnd(24.0,80.0);
			is_susceptible<-true;
			is_exposed<-false;
			is_infected <- false;
			is_resistant<-false;
      		}
			
			ask (nb_F_Awb_init*0.3) among F_Awb{
			pregnant <- true;
	contador_pregnant<-rnd(10,2800);}
			
//Creation of the Wwb agents	  
 		create WM_Jwb number: nb_WM_Jwb_init{
			location <- any_location_in(one_of(initlocw));
			speed <- rnd(1.0,5.0) #km/#h;
			age_in_months<- rnd(5.0,10.0);
			is_susceptible<-true;
			is_exposed<-false;
			is_infected <- false;
			is_resistant<-false;
      		}
      	create WF_Jwb number: nb_WF_Jwb_init{
			location <- any_location_in(one_of(initlocw));
			speed <- rnd(1.0,5.0) #km/#h;
			age_in_months<- rnd(5.0,10.0);
			is_susceptible<-true;
			is_exposed<-false;
			is_infected <- false;
			is_resistant<-false;
      		}
      	create WM_Ywb number: nb_WM_Ywb_init{
			location <- any_location_in(one_of(initlocw));
			speed <- rnd(3.0,7.0) #km/#h;
			age_in_months<- rnd(15.0,20.0);
			is_susceptible<-true;
			is_exposed<-false;
			is_infected <- false;
			is_resistant<-false;
      		}
      	create WF_Ywb number: nb_WF_Ywb_init{
			location <- any_location_in(one_of(initlocw));
			speed <- rnd(3.0,7.0) #km/#h;
			age_in_months<- rnd(15.0,20.0);	
			is_susceptible<-true;
			is_exposed<-false;
			is_infected <- false;
			is_resistant<-false;	
      		}
      		
      		ask (nb_WF_Ywb_init*0.1) among WF_Ywb{
			pregnant <- true;
				contador_pregnant<-rnd(10,2800);
			}
      		
      	create WM_Awb number: nb_WM_Awb_init{
			location <- any_location_in(one_of(initlocw));
			speed <- rnd(6.0,10.0) #km/#h;
			age_in_months<- rnd(24.0,80.0);
			is_susceptible<-true;
			is_exposed<-false;
			is_infected <- false;
			is_resistant<-false;
      		}
     	create WF_Awb number: nb_WF_Awb_init{
			location <- any_location_in(one_of(initlocw));
			speed <- rnd(6.0,10.0) #km/#h;
			age_in_months<- rnd(24.0,80.0);
			is_susceptible<-true;
			is_exposed<-false;
			is_infected <- false;
			is_resistant<-false;
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
	//int colorValue <- int(255*(usedbywb - 1)) update: int(255*(usedbywb - 1));
	//rgb color <- rgb(min([255, colorValue]),max ([0, 255 - colorValue]),0)  update: rgb(min([255, colorValue]),max ([0, 255 - colorValue]),0) ;
	
		aspect base {
		draw shape color: #black;//color;
	}
	
	}
	
species animal skills:[moving]{
	float speed;
	float age_in_months;
	//Movement
	//bool same_day<- false update: current_hour between(8,20);
	point target;
	wia current_target;
//	int leaving_hour <- 21;
//	int come_back_hour <- 7;
//	float detect_range<-1000#m;
	bool resting <- true ;
	bool need_to_rest <- true ;

	bool pregnant<- false;
	float incidence_distance<- 10.5#m;
	float feeding_distance<- 5.5#m;
	bool is_susceptible<-true;
	bool is_infected<-false;
	bool is_exposed<-false;
	bool is_resistant<-false;
	
	
	float contadorincu <- 0.0;
	reflex disease_adv when: is_exposed{
		contadorincu <-contadorincu + calcul_day;
		if contadorincu>=incub_period{
			if flip(delta){
			is_susceptible<-false;
			is_exposed<-false;
			is_infected <- false;
			is_resistant<-true;
			
		} else {
			is_susceptible<-false;
			is_exposed<-false;
			is_infected <- true;
			is_resistant<-false;
			//contadorincu <-0.0;
		}   
		//contadorincu <-0.0;
		}
	}

	
	reflex SpreadW_W when: is_infected and (ALLallS) at_distance transmission_range{
		ask (ALLallS) at_distance transmission_range
		{if flip(beta_ww){
			is_susceptible<-false;
			is_exposed<-true;
			is_infected <- false;
			is_resistant<-false;
				ask (cell overlapping self){
					wb_infection_events<-wb_infection_events+1;
				}
			}
		}
	}
// REFLEX TO SPREAD THE PATHOGEN TO THE ENVIRONMENT	
//		reflex SpreadW_P when: is_infected and (wia overlapping self){
//		ask (wia overlapping self)
//		{
//			if (is_susceptible) {
//				if  flip(beta_wp){
//					is_susceptible<-false;
//					is_infected <- true;
//				ask (cell overlapping self){
//					wbtoenv_infection_events<-wbtoenv_infection_events+1;
//				}
//				}
//			
//			}
//
//		}
//	}
	
	reflex ShallDie when: is_infected{
		if flip(nu) {
    	//Create another agent
		create (carcass)  {
			location <- myself.location ; 
		}
       	do die;
    }
    }

float contadorDie<-0.0;
reflex ControlDie when:is_infected{
	contadorDie<-contadorDie+calcul_day;
	if contadorDie>=10.0{
		create (carcass)  {
			location <- myself.location ; 
		}
		do die;
	}
}
	reflex aging {
			age_in_months <- age_in_months + calcul_month;//el 0.23 para semana / 0.0328 para día / 0.00137HORA
	if age_in_months >= 132{
	do die;
		}
	}
	
	
}

species carcass {
bool is_infected<-true;
reflex infect when:!empty((ALLallS) at_distance transmission_rangeB){
		ask (ALLallS) at_distance transmission_rangeB
		{if flip((beta_wp)/3){
			is_susceptible<-false;
			is_exposed<-true;
			is_infected <- false;
			is_resistant<-false;
				ask (cell overlapping self){
					carcass_infection_events<-carcass_infection_events+1;
				}
			}
		}
		
	}

float conta_carcass<-0.0;
//float t <- machine_time;
reflex shallDie {
	conta_carcass<-conta_carcass+calcul_day;
	
	if (!empty (building at_distance carcass_diastance)) {
		if conta_carcass >=1.5{
			do die;
			conta_carcass<-0.0;
		}
	}else if (conta_carcass>=patho_surv){
		do die;	
		conta_carcass<-0.0;}
		//write "duration of the last instructions: " + (machine_time - t);
  }
  aspect base {
		draw square(4) color:  #red ;
	}
}

species animal1 parent: animal{

	bool agressive_state <- false;
	float agressive_prob<- (1/3504);
	

//	reflex feed_event {
//		ask feeder_citi at_distance feeding_distance{
//			if flip (feeding_probability){
//				nb_feeding<-nb_feeding +1;
//				ask (cell overlapping self) {
//				wb_feed_events <- wb_feed_events + 1.0;
//			}
//				}
//		}
//	}
//	
//	reflex speed_people {
//		ask normal_citi at_distance incidence_distance{
//			speed<-max_speed;
//		}
//		ask pet_owners at_distance incidence_distance{
//			speed<-max_speed;
//		}
//		ask feeder_citi at_distance incidence_distance{
//			speed<-min_speed;
//		}
//	}
	
	reflex attackpeople when:agressive_state{
		ask people at_distance incidence_distance{
			if flip (aggression_probability){
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
	}
	
	
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
		reachable_feed <-((feeding_places ) at_distance detect_range);
		availa_f <-(reachable_feed ) where (each.food >= 0.35);
		
		//if (availa_feed = nil) {availa_feed  <- reachable_feed closest_to self;}	
		if (not same_day){
		visitados <- visitados + current_target;		
		availa_feed<-availa_f-visitados;
		//if (availa_feed = nil) {availa_feed  <- reachable_feed closest_to self;}	
		}else{	
		visitados <- [];	}
	
 }
	reflex leave when: (not resting)  and (target = nil)  {
		float quantity_food;
		ask (feeding_places overlapping self ){
		quantity_food<- food;
		}
		if 	quantity_food <= 0.10{
		//current_target <- need_to_rest ? (resting_places closest_to self) : ((availa_feed where (each.urban = "SI")) closest_to self);	
		
		if need_to_rest {
			current_target <-(resting_places closest_to self);
		}else if !empty (availa_feed where (each.is_urban=true)){
			availa_feed <-availa_feed where (each.is_urban=true);
			current_target <-availa_feed   closest_to self;}
			else {
				availa_feed <-availa_feed where (each.is_urban=false);
				current_target <-availa_feed  closest_to self;
			}
			
		//if (current_target = nil) {availa_feed  <- reachable_feed closest_to self;}		
		target <- any_location_in(current_target);	}	
		else if  need_to_rest {
		current_target <-(resting_places closest_to self);			
		target <- any_location_in(current_target);
		}
	}	

   	reflex moving when: target != nil {
		path path_followed <- self goto [target::target, on::road_network, return_path:: true];
//		list<geometry> segments <- path_followed.segments;
//		loop line over: segments {
//			float dist <- line.perimeter;
//			ask road(path_followed agent_from_geometry line) { 
//				usedbywb <- usedbywb + 1;
//			}
//		}
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
//	reflex real_presence{
//		
//	}
	reflex become_agressive {
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
		
//  aspect base {
//		draw square(35) color: #yellow;
//		
//	}
	}	

//Females
species SFW parent:animal1{
	int contador_pregnant;	
	int contador_breeding;	
	float proba_reproduce;	
	bool is_reprotime <- false update: current_month <= 3 or current_month >= 11 ;
	float sex_ratio <- 0.5;
	bool pregnant<- false;
	reflex reproduce when: (!empty (M_Awb at_distance reproduction_distance)) and ((is_reprotime) and ((not pregnant) and (age_in_months >=6.0))) {
		if flip(proba_reproduce) {
		pregnant<-true;
		} 	
	}
	
	reflex reproduce2 when: (!empty (WM_Awb at_distance reproduction_distance)) and ((is_reprotime) and ((not pregnant) and (age_in_months >=6.0))) {
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
		if myself.is_susceptible{
			self.is_susceptible<-true;
			self.is_exposed<-false;
			self.is_infected <- false;
			self.is_resistant<-false;
		}else if myself.is_infected{
			self.is_susceptible<-false;
			self.is_exposed<-true;
			self.is_infected <- false;
			self.is_resistant<-false;
		}else if myself.is_resistant{
			self.is_susceptible<-true;
			self.is_exposed<-false;
			self.is_infected <- false;
			self.is_resistant<-false;
		}  }
			} else {
				create (F_Jwb) number:1{
				location <-myself.location;
				if myself.is_susceptible{
			self.is_susceptible<-true;
			self.is_exposed<-false;
			self.is_infected <- false;
			self.is_resistant<-false;
		}else if myself.is_infected{
			self.is_susceptible<-false;
			self.is_exposed<-true;
			self.is_infected <- false;
			self.is_resistant<-false;
		}else if myself.is_resistant{
			self.is_susceptible<-true;
			self.is_exposed<-false;
			self.is_infected <- false;
			self.is_resistant<-false;
		}  
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
		if myself.is_susceptible{
			self.is_susceptible<-true;
			self.is_exposed<-false;
			self.is_infected <- false;
			self.is_resistant<-false;
		}else if myself.is_infected{
			self.is_susceptible<-false;
			self.is_exposed<-true;
			self.is_infected <- false;
			self.is_resistant<-false;
		}else if myself.is_resistant{
			self.is_susceptible<-true;
			self.is_exposed<-false;
			self.is_infected <- false;
			self.is_resistant<-false;
		} 
		}
			} else {
				create (F_Jwb) number:1{
				location <-myself.location;
				if myself.is_susceptible{
			self.is_susceptible<-true;
			self.is_exposed<-false;
			self.is_infected <- false;
			self.is_resistant<-false;
		}else if myself.is_infected{
			self.is_susceptible<-false;
			self.is_exposed<-true;
			self.is_infected <- false;
			self.is_resistant<-false;
		}else if myself.is_resistant{
			self.is_susceptible<-true;
			self.is_exposed<-false;
			self.is_infected <- false;
			self.is_resistant<-false;
		} 
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
		if myself.is_susceptible{
			self.is_susceptible<-true;
			self.is_exposed<-false;
			self.is_infected <- false;
			self.is_resistant<-false;
		}else if myself.is_exposed{
			self.is_susceptible<-false;
			self.is_exposed<-true;
			self.is_infected <- false;
			self.is_resistant<-false;
		}else if myself.is_infected{
			self.is_susceptible<-false;
			self.is_exposed<-false;
			self.is_infected <- true;
			self.is_resistant<-false;
		}else if myself.is_resistant{
			self.is_susceptible<-false;
			self.is_exposed<-false;
			self.is_infected <- false;
			self.is_resistant<-true;
		} 
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
		if myself.is_susceptible{
			self.is_susceptible<-true;
			self.is_exposed<-false;
			self.is_infected <- false;
			self.is_resistant<-false;
		}else if myself.is_exposed{
			self.is_susceptible<-false;
			self.is_exposed<-true;
			self.is_infected <- false;
			self.is_resistant<-false;
		}else if myself.is_infected{
			self.is_susceptible<-false;
			self.is_exposed<-false;
			self.is_infected <- true;
			self.is_resistant<-false;
		}else if myself.is_resistant{
			self.is_susceptible<-false;
			self.is_exposed<-false;
			self.is_infected <- false;
			self.is_resistant<-true;
		} 
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
		if myself.is_susceptible{
			self.is_susceptible<-true;
			self.is_exposed<-false;
			self.is_infected <- false;
			self.is_resistant<-false;
		}else if myself.is_exposed{
			self.is_susceptible<-false;
			self.is_exposed<-true;
			self.is_infected <- false;
			self.is_resistant<-false;
		}else if myself.is_infected{
			self.is_susceptible<-false;
			self.is_exposed<-false;
			self.is_infected <- true;
			self.is_resistant<-false;
		}else if myself.is_resistant{
			self.is_susceptible<-false;
			self.is_exposed<-false;
			self.is_infected <- false;
			self.is_resistant<-true;
		} 
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
		if myself.is_susceptible{
			self.is_susceptible<-true;
			self.is_exposed<-false;
			self.is_infected <- false;
			self.is_resistant<-false;
		}else if myself.is_exposed{
			self.is_susceptible<-false;
			self.is_exposed<-true;
			self.is_infected <- false;
			self.is_resistant<-false;
		}else if myself.is_infected{
			self.is_susceptible<-false;
			self.is_exposed<-false;
			self.is_infected <- true;
			self.is_resistant<-false;
		}else if myself.is_resistant{
			self.is_susceptible<-false;
			self.is_exposed<-false;
			self.is_infected <- false;
			self.is_resistant<-true;
		} 
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
//	float speed <- 10 #km/#h;
//	float age_in_months;
//	//Movement
//	//bool same_day<- false update: current_hour between(8,20);
//	point target;
//	wia current_target;
//	int leaving_hour <- 20;
//	//float detect_range<-1000#m;
//	bool resting <- true ;
//	bool need_to_rest <- true ;
//	//bool is_reprotime <- true update: current_month <= 4 or current_month >= 10 ;
////	float sex_ratio <- 0.5;
//	bool pregnant<- false;
//	//float habit_prob<- 0.15;
//	bool is_susceptible<-true;
//	bool is_infected<-false;
//	bool is_exposed<-false;
//	bool is_resistant<-false;
	
	
//	reflex updatenbs2{
//	all_toge2<-  (WM_Jwb + WM_Ywb + WM_Awb + WF_Jwb +WF_Ywb  +WF_Awb);
//	 j_toge2<- (WM_Jwb + WF_Jwb);
//	 y_toge2<- (WM_Ywb + WF_Ywb);
//	 a_toge2<- (WM_Awb + WF_Awb);
//	}
	
	
//float contadorincu <- 0.0;
//	reflex disease_adv when: is_exposed{
//		contadorincu <-contadorincu + calcul_day;
//		if contadorincu>=incub_period{
//			if flip(delta){
//			is_susceptible<-false;
//			is_exposed<-false;
//			is_infected <- false;
//			is_resistant<-true;
//		} else {
//			is_susceptible<-false;
//			is_exposed<-false;
//			is_infected <- true;
//			is_resistant<-false;
//		}   
//		contadorincu <-0.0;
//		}
//	}
//	reflex infect when: is_infected{
//		if flip(nu) {
//    	//Create another agent
////		create species(carcass)  {
////			location <- myself.location ; 
////		}
//       	do die;
//    }
//		ask (all_toge where each.is_susceptible) at_distance transmission_range
//		{
//			if flip(beta_ww){
//			is_susceptible<-false;
//			is_exposed<-true;
//			is_infected <- false;
//			is_resistant<-false;
//				ask (cell overlapping self){
//					wb_infection_events<-wb_infection_events+1;
//				}
//			}
//
//		}
//		ask (all_toge2 where each.is_susceptible) at_distance transmission_range
//		{
//			if flip(beta_ww)
//			{
//			is_susceptible<-false;
//			is_exposed<-true;
//			is_infected <- false;
//			is_resistant<-false;
//				ask (cell overlapping self){
//					wb_infection_events<-wb_infection_events+1;
//				}
//			} 
//			
//		}
//	}
////	//Reflex to kill the agent according to the probability of dying
////    reflex shallDie when:is_infected{
////    	if flip(nu) {
////    	//Create another agent
//////		create species(carcass)  {
//////			location <- myself.location ; 
//////		}
////       	do die;
////    }
////    }
//    
//	reflex aging {
//			age_in_months <- age_in_months + 0.00137;//el 0.23 para semana / 0.0328 para día / 0.00137HORA
//			if age_in_months >= 132{
//	do die;
//		}
//	}
	
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
//		if need_to_rest {
//			current_target <-(resting_places closest_to self);
//		}else {
//			availa_feed <-availa_feed where (each.urban = "NO");
//			current_target <-availa_feed   closest_to self;}
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
		if myself.is_susceptible{
			self.is_susceptible<-true;
			self.is_exposed<-false;
			self.is_infected <- false;
			self.is_resistant<-false;
		}else if myself.is_exposed{
			self.is_susceptible<-false;
			self.is_exposed<-true;
			self.is_infected <- false;
			self.is_resistant<-false;
		}else if myself.is_infected{
			self.is_susceptible<-false;
			self.is_exposed<-false;
			self.is_infected <- true;
			self.is_resistant<-false;
		}else if myself.is_resistant{
			self.is_susceptible<-false;
			self.is_exposed<-false;
			self.is_infected <- false;
			self.is_resistant<-true;
		} 
			}
		} else {
		create (WM_Ywb) number:1 {
		int age_month_init<-0;
		location <-myself.location;
		age_in_months<- 12.0;
		if myself.is_susceptible{
			self.is_susceptible<-true;
			self.is_exposed<-false;
			self.is_infected <- false;
			self.is_resistant<-false;
		}else if myself.is_exposed{
			self.is_susceptible<-false;
			self.is_exposed<-true;
			self.is_infected <- false;
			self.is_resistant<-false;
		}else if myself.is_infected{
			self.is_susceptible<-false;
			self.is_exposed<-false;
			self.is_infected <- true;
			self.is_resistant<-false;
		}else if myself.is_resistant{
			self.is_susceptible<-false;
			self.is_exposed<-false;
			self.is_infected <- false;
			self.is_resistant<-true;
		} 
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
		if myself.is_susceptible{
			self.is_susceptible<-true;
			self.is_exposed<-false;
			self.is_infected <- false;
			self.is_resistant<-false;
		}else if myself.is_exposed{
			self.is_susceptible<-false;
			self.is_exposed<-true;
			self.is_infected <- false;
			self.is_resistant<-false;
		}else if myself.is_infected{
			self.is_susceptible<-false;
			self.is_exposed<-false;
			self.is_infected <- true;
			self.is_resistant<-false;
		}else if myself.is_resistant{
			self.is_susceptible<-false;
			self.is_exposed<-false;
			self.is_infected <- false;
			self.is_resistant<-true;
		} 
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
		if myself.is_susceptible{
			self.is_susceptible<-true;
			self.is_exposed<-false;
			self.is_infected <- false;
			self.is_resistant<-false;
		}else if myself.is_exposed{
			self.is_susceptible<-false;
			self.is_exposed<-true;
			self.is_infected <- false;
			self.is_resistant<-false;
		}else if myself.is_infected{
			self.is_susceptible<-false;
			self.is_exposed<-false;
			self.is_infected <- true;
			self.is_resistant<-false;
		}else if myself.is_resistant{
			self.is_susceptible<-false;
			self.is_exposed<-false;
			self.is_infected <- false;
			self.is_resistant<-true;
		} 
			}
		} else {
		create (WF_Ywb) number:1 {
		int age_month_init<-0;
		location <-myself.location;
		age_in_months<- 12.0;
		if myself.is_susceptible{
			self.is_susceptible<-true;
			self.is_exposed<-false;
			self.is_infected <- false;
			self.is_resistant<-false;
		}else if myself.is_exposed{
			self.is_susceptible<-false;
			self.is_exposed<-true;
			self.is_infected <- false;
			self.is_resistant<-false;
		}else if myself.is_infected{
			self.is_susceptible<-false;
			self.is_exposed<-false;
			self.is_infected <- true;
			self.is_resistant<-false;
		}else if myself.is_resistant{
			self.is_susceptible<-false;
			self.is_exposed<-false;
			self.is_infected <- false;
			self.is_resistant<-true;
		} 
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
		if myself.is_susceptible{
			self.is_susceptible<-true;
			self.is_exposed<-false;
			self.is_infected <- false;
			self.is_resistant<-false;
		}else if myself.is_exposed{
			self.is_susceptible<-false;
			self.is_exposed<-true;
			self.is_infected <- false;
			self.is_resistant<-false;
		}else if myself.is_infected{
			self.is_susceptible<-false;
			self.is_exposed<-false;
			self.is_infected <- true;
			self.is_resistant<-false;
		}else if myself.is_resistant{
			self.is_susceptible<-false;
			self.is_exposed<-false;
			self.is_infected <- false;
			self.is_resistant<-true;
		} 
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
      float foodProdU <- rnd(0.009,0.04);// 0.045;//0.033;//0.016 para el 80% diario
      float foodProdN <- rnd(0.006,0.02);//0.016;//0.0104 ;//es el 15% diario //0.00209 ES 0.1(10%) ENTRE 48 STEPS DE 12 HORAS A 4 STEPS LA HORA (15 MIN)
      float foodProdS <- (foodProdN/ 2) ;
      float food<-0.9 min: 0.00 max: maxFood;
     float foodini;
	  bool growing_time <- false update: current_hour between(8,20);//<= 3 or current_month >= 11 ;
	 bool is_infected<-false;
	 bool is_susceptible<-true;
	 
//	 reflex infect when: is_infected{
//		ask (ALLallS) overlapping self
//		{
//			if myself.urban="SI"{
//				if flip(beta_wp)
//			{
//			is_susceptible<-false;
//			is_exposed<-true;
//			is_infected <- false;
//			is_resistant<-false;
//				ask (cell overlapping self){
//					envtowb_infection_events<-envtowb_infection_events+1;
//				}
//			}
//			}else{
//				if flip((10000*beta_wp)/myself.surface)
//			{
//			is_susceptible<-false;
//			is_exposed<-true;
//			is_infected <- false;
//			is_resistant<-false;
//				ask (cell overlapping self){
//					envtowb_infection_events<-envtowb_infection_events+1;
//				}
//			}
//			}
//			
//
//		}
//	}


reflex infecturban when: is_infected and is_urban{
	ask (ALLallS) at_distance  transmission_range{
			if flip(beta_wp)
			{
			is_susceptible<-false;
			is_exposed<-true;
			is_infected <- false;
			is_resistant<-false;
				ask (cell overlapping self){
					envtowb_infection_events<-envtowb_infection_events+1;
				}
			}
	}
}
//
//
//reflex infectCNP when: is_infected and not is_urban{
//	ask (ALLallS) at_distance  transmission_range{
//			if flip(beta_wp)
//			{
//			is_susceptible<-false;
//			is_exposed<-true;
//			is_infected <- false;
//			is_resistant<-false;
//				ask (cell overlapping self){
//					envtowb_infection_events<-envtowb_infection_events+1;
//				}
//			}
//	}
//}

// reflex infect when: is_infected{
// 	ask (ALLallS) overlapping self{
// 		if self.is_susceptible {
// 			if myself.is_urban=true{
//				if flip(beta_wp)
//			{
//			is_susceptible<-false;
//			is_exposed<-true;
//			is_infected <- false;
//			is_resistant<-false;
//				ask (cell overlapping self){
//					envtowb_infection_events<-envtowb_infection_events+1;
//				}
//			}
//			}else{
//				if flip((10000*beta_wp)/myself.surface)
//			{
//			is_susceptible<-false;
//			is_exposed<-true;
//			is_infected <- false;
//			is_resistant<-false;
//				ask (cell overlapping self){
//					envtowb_infection_events<-envtowb_infection_events+1;
//				}
//			}
//			}
// 			}
// 			
// 	}
// }
 
	 

float conta_pathogen<-0.0;
reflex PathogenDegradation  when:is_infected{
	conta_pathogen<-conta_pathogen+calcul_day;
	if is_urban {
		if (conta_pathogen>=1.0){
		is_infected <- false;
		is_susceptible<-true;
		conta_pathogen<-0.0;	}
	}else{
		if (conta_pathogen>=5.5){
		is_infected <- false;
		is_susceptible<-true;
		conta_pathogen<-0.0;
	}
  }
  }
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
	int start_natu;// update: min_natu_start + rnd (max_natu_start - min_natu_start);
	int end_natu;// update: min_natu_end + rnd (max_natu_end - min_natu_end) ;
	float outdoor_probability <- 0.332;
	float leissure_prob <- 0.332;
	float health_prob <- (1.0*calcul_year);
	string objective ; 
	point the_target <- nil ;
	float interaction_distance<- 15.5#m;
	//float incidence_distance<- 10.5#m;
//	float feeding_distance<- 5.5#m;
	float feeding_probability;//<- 0.037;
	float aggression_probability;//_F<- 0.00869;	
	float car_distance <-2000.0#m;
	int gravedad;
	int estancia;
	//float distance_to_destination <- 0.0 update: self distance_to destination;
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
	//if ((self distance_to the_target) >= car_distance)
	reflex move when: the_target != nil {
		do goto target: the_target on: road_network ; 
		//path path_followed <- self goto [target::the_target, on::road_network, return_path:: true];
//		float dista<-length (path_followed);
//		if ((dista) >= car_distance){
//			speed <- speedcar;
//		} else {
//			speed<-speed;
//		}
		if ((self distance_to the_target) >= car_distance){
			speed <- speedcar;
		} else {
			speed<-speed;
		}
		
		if the_target = location {
			the_target <- nil ;}
	}


	  aspect base{
	  	draw square (5)color: #red;}
}

//species feeder_citi parent: people{
//	float aggression_probability_F<- 0.0869;	
//	
//	init{
//	aggression_probability<-aggression_probability_F;
//	}
//	
//	float feeding_probability<- 0.37;
//
//	aspect base {
//		draw triangle(55) color: #lime;}
//}
//
//species pet_owners parent: people{
//	float aggression_probability_PO<- 0.0379;
//	
//	init{
//	aggression_probability<- aggression_probability_PO;
//	}
//	
//	aspect base {
//		draw triangle(55) color: #silver;}
//}
//
//species normal_citi parent: people{
//	float aggression_probability_NC<- 0.0126;
//	init{
//	aggression_probability<- aggression_probability_NC;
//	}
//	
//	aspect base {
//		draw triangle(55) color: #black;}
//}

grid cell height: 100 width: 100 neighbors: 8{
	int wb_presence <- 0;
	int wb_presenceI <- 0;
	int wb_presenceE <- 0;
	int wb_attacks<-0;
	int wb_feed_events<-0;
	
	int wb_infection_events<-0;
	int wbtowb_infection_events<-0;
	int wbtoenv_infection_events<-0;
	int envtowb_infection_events<-0;
	int carcass_infection_events<-0;
	//int c_infection_events<-0;
	//color updated according to the wb_presence level (from red - high wb_presence to green - no wb_presence)
	rgb color <- #green;// update: rgb(255 *(wb_infection_events/30.0) , 255 * (1 - (wb_infection_events/30.0)), 0.0);
}

//experiment Benchmarking type: gui benchmark: true { }
//experiment MyTest type: test autorun: true { }

experiment ASFV type:gui {
	output {
		
		display map type:opengl{
			//grid cell elevation: wb_presence * 3.0 triangulation: true transparency: 0.9;
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
			species people aspect: base;
			species carcass aspect:base;
//			species feeder_citi aspect: base;
//		    species normal_citi aspect: base;
//			species pet_owners aspect: base;
					}
		display chart2 refresh: every(24 # cycles){
			chart "Disease spreading" type: series
			{
		data "SUSCEPTIBLE SWB" value: nb_SUS_SW color: #limegreen;
		data "SUSCEPTIBLE WWB" value: nb_SUS_WW color: #dodgerblue;
		data "EXPOSED SWB" value: nb_EXP_SW color: #orange;
		data "EXPOSED WWB" value: nb_EXP_WW color: #magenta;
		data "INFECTED SWB" value: nb_INF_SW color: #red;
		data "INFECTED WWB" value: nb_INF_WW color: #yellow;
		data "RESISTANT SWB" value: nb_RES_SW color: #seagreen;
		data "RESISTANT WWB" value: nb_RES_WW color: #midnightblue;
			}
			}
			
			display chart3 refresh: every(168 # cycles){
			chart "Disease spreading" type: series
			{
		data "SUSCEPTIBLE SWB" value: nb_SUS_SW color: #limegreen;
		data "SUSCEPTIBLE WWB" value: nb_SUS_WW color: #dodgerblue;
		data "EXPOSED SWB" value: nb_EXP_SW color: #orange;
		data "EXPOSED WWB" value: nb_EXP_WW color: #magenta;
		data "INFECTED SWB" value: nb_INF_SW color: #red;
		data "INFECTED WWB" value: nb_INF_WW color: #yellow;
		data "RESISTANT SWB" value: nb_RES_SW color: #seagreen;
		data "RESISTANT WWB" value: nb_RES_WW color: #midnightblue;
			}
			}
			
		display chart refresh: every(4 # cycles){
			chart "Disease spreading" type: series
			{
		
		data "SUSCEPTIBLE WWB" value: nb_SUS_WW color: #dodgerblue;
		data "EXPOSED WWB" value: nb_EXP_WW color: #magenta;
		data "INFECTED WWB" value: nb_INF_WW color: #yellow;
		data "RESISTANT WWB" value: nb_RES_WW color: #midnightblue;
		data "SUSCEPTIBLE SWB" value: nb_SUS_SW color: #limegreen;
		data "EXPOSED SWB" value: nb_EXP_SW color: #orange;
		data "INFECTED SWB" value: nb_INF_SW color: #red;
		data "RESISTANT SWB" value: nb_RES_SW color: #seagreen;
		
			}
			
			//data "SUSCEPTIBLE TWB" value: all_toge count (each.is_susceptible)+all_toge2 count (each.is_susceptible) color: #green;
		//data "INFECTED TWB" value: all_toge count (each.is_infected)+all_toge2 count (each.is_infected) color: #red;
//		data "number_of_wb1_infected" value: nb_infected color: #black ;
//		data "number_of_wb2_infected" value: nb_infected2 color: #black ;			
//data "number_of_people" value: nb_people color: #black ;
		//data "number_of_attack_events" value: nb_agressions color: #black;
		//data "number_of_feedingk_events" value: nb_feed_events color: #black;
		//data "number_of_attacking_events" value: nb_attacks color: #black;
		//data "number_of_feeding_events" value: nb_feeding color: #black;nb_wb_not_infected
		//data "number_of_wb_infected" value: wb_infected color: #black ;
		//data "number_of_wb_susceptible" value: nb_wb_not_infected color: #black ;
		}
		
		monitor "Date" value: current_date;
		monitor "number_wia_infected" value: nbinfwia color: #black ;
		monitor "number_wb_infected" value: wb_infected color: #black ;
		monitor "number_wb_not_infected" value: nb_wb_not_infected color: #black ;
		monitor "infected_rate" value: infected_rate color: #black ;
		monitor "number_of_SWB" value: nb_all_wb color: #black ;
		monitor "number_of_WWB" value: nb_Wall_wb color: #black ;
		monitor "SUSCEPTIBLE SWB" value: nb_SUS_SW color: #limegreen;
		monitor "EXPOSED SWB" value: nb_EXP_SW color: #orange;
		monitor "INFECTED SWB" value: nb_INF_SW color: #red;
		monitor "RESISTANT SWB" value: nb_RES_SW color: #seagreen;
		
		monitor "SUSCEPTIBLE WWB" value: nb_SUS_WW color: #dodgerblue;
		monitor "EXPOSED WWB" value: nb_EXP_WW color: #magenta;
		monitor "INFECTED WWB" value: nb_INF_WW color: #yellow;
		monitor "RESISTANT WWB" value: nb_RES_WW color: #midnightblue;
//		monitor "number_of_wb2_infected" value: nb_infected2 color: #black ;nb_RES_SW
//		monitor "number_of_attack_events" value: nb_agressions color: #black;
	//	monitor "number_of_feeding_events" value: nb_feeding color: #black;
//		monitor "number_of_Males_juveniles" value: nb_M_Jwb color: #lightgrey ;
//		monitor "number_of_Females_juveniles" value: nb_F_Jwb color: #yellow ;
//		monitor "number_of_Males_yearlings" value: nb_M_Ywb color: #darkgrey ;
//		monitor "number_of_Females_yearlings" value: nb_F_Ywb color: #orange ;
//		monitor "number_of_Males_adults" value: nb_M_Awb color: #black ;
//		monitor "number_of_Females_adults" value: nb_F_Awb color: #red ;
//		monitor "number_of_WMales_juveniles" value: nb_WM_Jwb color: #lightgrey ;
//		monitor "number_of_WFemales_juveniles" value: nb_WF_Jwb color: #yellow ;
//		monitor "number_of_WMales_yearlings" value: nb_WM_Ywb color: #darkgrey ;
//		monitor "number_of_WFemales_yearlings" value: nb_WF_Ywb color: #orange ;
//		monitor "number_of_WMales_adults" value: nb_WM_Awb color: #black ;
//		monitor "number_of_WFemales_adults" value: nb_WF_Awb color: #red ;


		//monitor "number_of_feedingk_events" value: nb_feed_events color: #black;
		//monitor "number_of_attacking_events" value: nb_attacks color: #black;
		//monitor "number_of_feeding_events" value: nb_feeding color: #black;
	}
}