# -*- coding: utf-8 -*-
"""
Created on Mon Mar 30 11:25:46 2020

@author: Green Winters
Source Code Reference: https://fiftyexamples.readthedocs.io/en/latest/gravity.html
https://github.com/akuchling/50-examples/blob/master/gravity.rst

"""

import math
import pandas as pd
from time import process_time
import os
import sys

##Set the global enviornment
#Set the global constants
G = 6.67428e-11           # The gravitational constant G
AU = (149.6e6 * 1000)     # 149.6 million km, in meters.
SCALE = 250 / AU

##Check and set the correct/current directory
##Read in the data from the current directory
#List of datasets with bodies for the simulation
#infile = "object_list_planets.csv"
#infile = "object_list_38_objects.csv"
infile = "object_list_500_objects.csv"
#infile = "object_list_1000_objects.csv"
#infile = "object_list_2000_objects.csv"
#infile = "object_list_4000_objects.csv"
#infile = "object_list_8000_objects.csv"

if len(sys.argv) > 1 and os.path.exists(sys.argv[1]):
    csv_path = sys.argv[1]
else:
    csv_path = r'C:\\Users\\bahir\\Desktop\\CSI 702\\Final Project'+infile

init_df = pd.read_csv(csv_path, dtype={ "name":str, "mass":float, "px":float, "py":float, "vx":float, "vy": float, "total_fx":float, "total_fy":float})
init_df = init_df.set_index('index')

rolling_df = pd.DataFrame(columns = ['step','name','mass','px','py','vx','vy'])

#Sets the length and moves the simulation
def loop(func_df,rolling_df):
    timestep = 24*3600  # One day
    step = 0
    #List bodies to verify the simulation is running correctly
    planet_checklist = ["Sun","Mercury","Venus","Earth", "Mars", "Jupiter", "Saturn",
                        "Uranus","Neptune", "Pluto"]
    parameter = func_df.index.tolist()
    while step <= 370:
        for body in parameter:
            #Add up all of the forces exerted on 'body' from the other bodies in the simulation
            list_bodies = parameter[:]
            list_bodies.remove(body)
            total_fx = total_fy = 0.0
            for other in list_bodies: #Returns the force exerted upon this body by the other body.
                sx = func_df.loc[body,'px']
                sy = func_df.loc[body,'py']
                ox = func_df.loc[other,'px']
                oy = func_df.loc[other,'py']
                dx = (ox-sx)
                dy = (oy-sy)
                d2 = dx**2 + dy**2                  
                # get a ZeroDivisionError exception further down.
                if d2 == 0:
                    raise ValueError("Collision between objects %r and %r"
                         % (body, other))

                # Compute the force of attraction
                f = G * func_df.loc[body,'mass'] * func_df.loc[other,'mass'] / d2   
                # Compute the direction of the force.
                theta = math.atan2(dy, dx)
                fx = math.cos(theta) * f
                fy = math.sin(theta) * f 
                #fx, fy = attraction(body, other)
                total_fx += fx
                total_fy += fy
            #Record the total force exerted.
            func_df.loc[body,'total_fx'] = total_fx
            func_df.loc[body,'total_fy'] = total_fy        
        #Update velocities and positions based upon on the force.
        #for body in parameter:
            func_df.loc[body,'vx'] += func_df.loc[body,'total_fx'] / func_df.loc[body,'mass'] * timestep
            func_df.loc[body,'vy'] += func_df.loc[body,'total_fy'] / func_df.loc[body,'mass'] * timestep
            func_df.loc[body,'px'] += func_df.loc[body,'vx'] * timestep
            func_df.loc[body,'py'] += func_df.loc[body,'vy'] * timestep
        #Append every 50th step to the rolling_df
        #Print what's in memory
        stop = 50
        if step==stop:
            for body in planet_checklist:
                step_Vector = pd.Series({"step":step})
                step_Vector = step_Vector.append(func_df.loc[body,'name':'vy'])
                rolling_df = rolling_df.append(step_Vector, ignore_index=True)            
        step += 1
    return rolling_df, stop
    
#Runs the simulation
def main():
    start_time = process_time()
    results, final_step = loop(init_df, rolling_df)
    print("Time of the Serial simulation", process_time()-start_time, " seconds")
    print("Saving Serial Results to Memory")
    #Save Planets' 500th results to file
    results.to_csv('/home/badewunm/env/'+str(final_step)+'th_step_results_'+str(len(init_df))+'bodies_serial.csv')

if __name__ == "__main__":
    main()
"""
Works Referenced
https://docs.python.org/3/library/time.html#time.perf_counter
https://docs.python.org/2/library/timeit.html
https://www.programcreek.com/python/example/84234/time.process_time
https://stackoverflow.com/questions/19951816/python-changes-to-my-copy-variable-affect-the-original-variable
http://www.scholarpedia.org/article/N-body_simulations
https://docs.dask.org/en/latest/dataframe-api.html
https://stackoverflow.com/questions/44602766/unpacking-result-of-delayed-function
https://stackoverflow.com/questions/48728383/dask-delayed-object-of-unspecified-length-not-iterable-error-when-combining-dict
https://examples.dask.org/applications/embarrassingly-parallel.html
https://docs.scipy.org/doc/scipy/reference/generated/scipy.stats.binned_statistic_2d.html

Dask Library Reference
https://distributed.dask.org/en/latest/client.html
https://distributed.dask.org/en/latest/quickstart.html
https://docs.dask.org/en/latest/
https://docs.dask.org/en/latest/setup.html
https://docs.dask.org/en/latest/delayed-best-practices.html#avoid-calling-delayed-within-delayed-functions #Very helpful
https://docs.dask.org/en/latest/delayed-api.html


Data
https://ssd.jpl.nasa.gov/sbdb_query.cgi#x
https://nssdc.gsfc.nasa.gov/planetary/factsheet/asteroidfact.html
https://ssd.jpl.nasa.gov/horizons.cgi


Methodologies
https://docs.dask.org/en/latest/
https://docs.rapids.ai/api/cudf/stable/10min.html
https://github.com/classner/pymp
https://docs.python.org/2/library/multiprocessing.html#using-a-pool-of-workers
https://stackoverflow.com/questions/33480675/multiprocessing-on-a-set-number-of-cores

"""