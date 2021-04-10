# -*- coding: utf-8 -*-
"""
Created on Mon Mar 30 11:25:46 2020

#Uses Delays

The threaded scheduler executes computations with a local 
multiprocessing.pool.ThreadPool. It is lightweight and requires no setup. 
It introduces very little task overhead (around 50us per task) and, because 
everything occurs in the same process, it incurs no costs to transfer data 
between tasks. However, due to Python’s Global Interpreter Lock (GIL), this 
scheduler only provides parallelism when your computation is dominated by 
non-Python code, as is primarily the case when operating on numeric data in 
NumPy arrays, Pandas DataFrames, or using any of the other C/C++/Cython based 
projects in the ecosystem.

@author: Green Winters
Source Code Reference: https://fiftyexamples.readthedocs.io/en/latest/gravity.html
https://github.com/akuchling/50-examples/blob/master/gravity.rst

"""

import math
import pandas as pd
from time import process_time
import os
import sys
import dask
dask.config.set(scheduler='threads') #toggle this if there is more complex architechture 
#dask.config.set(scheduler='processes') #Produces no results

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
    csv_path = "C:/Users/bahir/Desktop/CSI 702/Final Project/"+ infile
    
init_df = pd.read_csv(csv_path, dtype={ "name":str, "mass":float, "px":float, "py":float, "vx":float, "vy": float, "total_fx":float, "total_fy":float})
init_df = init_df.set_index('index')

#Calculates all of the forces of the other bodies on the submitted prime body
def loop_force(body, remote_df):    
    all_other_bodies = global_list_bodies[:]
    all_other_bodies.remove(body)
    total_fx = total_fy = 0.0
    for other in all_other_bodies: #Returns the force exerted upon this body by the other body.
        sx = remote_df.loc[body,'px']
        sy = remote_df.loc[body,'py']
        ox = remote_df.loc[other,'px']
        oy = remote_df.loc[other,'py']
        dx = (ox-sx)
        dy = (oy-sy)
        d2 = dx**2 + dy**2                  
        # get a ZeroDivisionError exception further down.
        if d2 == 0:
            raise ValueError("Collision between objects %r and %r"
                 % (body, other))

        # Compute the force of attraction
        f = G * remote_df.loc[body,'mass'] * remote_df.loc[other,'mass'] / d2   
        # Compute the direction of the force.
        theta = math.atan2(dy, dx)
        fx = math.cos(theta) * f
        fy = math.sin(theta) * f 
        total_fx += fx
        total_fy += fy
    #Return the total force exerted.
    return total_fx, total_fy, body 

    
#Runs the simulation
timestep = 24*3600  # One day in seconds
global_list_bodies = init_df.index.tolist()
planet_checklist = ["Sun","Mercury","Venus","Earth", "Mars", "Jupiter", "Saturn",
                    "Uranus","Neptune", "Pluto"]
def main():
    step = 0
    rolling_df = pd.DataFrame(columns = ['step','name','mass','px','py','vx','vy'])
    start_time = process_time()
    while step <= 370: 
        #Calculate Force on each body and store to a list
        delay_results = []
        for body in global_list_bodies:
            delay_fx, delay_fy, delay_body = dask.delayed(loop_force,nout=3)(body,init_df)
            delay_results.append([delay_body, delay_fx, delay_fy])
        
        delay_results = dask.persist(*delay_results) 
        force_values = dask.compute(delay_results)
        #Update velocities and positions based upon on the force.
        for i in range(0,len(force_values[0])):
            init_df.loc[force_values[0][i][0],'vx'] += force_values[0][i][1] / init_df.loc[force_values[0][i][0],'mass'] * timestep
            init_df.loc[force_values[0][i][0],'vy'] += force_values[0][i][2]  / init_df.loc[force_values[0][i][0],'mass'] * timestep
            init_df.loc[force_values[0][i][0],'px'] += init_df.loc[force_values[0][i][0],'vx'] * timestep
            init_df.loc[force_values[0][i][0],'py'] += init_df.loc[force_values[0][i][0],'vy'] * timestep
        del delay_results, force_values
        #Print  the last step results
        if body in planet_checklist and step==370:
            step_Vector = pd.Series({"step":step})
            step_Vector = step_Vector.append(init_df.loc[body,'name':'vy'])
            rolling_df = rolling_df.append(step_Vector, ignore_index=True)
            #Print the new entries to the screen
            #s = 'Step #{}  {:<8}  Pos.={:>6.2f} {:>6.2f} Vel.={:>10.3f} {:>10.3f}'.format(step, step_Vector['name'], step_Vector['px']/AU, step_Vector['py']/AU, step_Vector['vx'], step_Vector['vy'])
            #s = '{:<8}  Pos.={:>6.2f} {:>6.2f} Vel.={:>10.3f} {:>10.3f}'.format(func_df.loc[body,'name'], func_df.loc[body,'px']/AU, func_df.loc[body,'py']/AU, func_df.loc[body,'vx'], func_df.loc[body,'vy'])
            #print(s)
            #del s, step_Vector
        #else:
            #print('Processing Step #',step)
        step += 1
    print("Time of the Delay Local simulation", process_time()-start_time, " seconds")
    print("Saving Delay Results to Memory")
    #Save Planets' 500th results to file
    rolling_df.to_csv('/home/badewunm/env/'+str(step)+'th_step_results_'+str(len(init_df))+'bodies_delay.csv')
   

if __name__ == "__main__":
    main()

#client.cancel()
#client.shutdown()
"""
Works Referenced
https://www.geeksforgeeks.org/different-ways-to-create-pandas-dataframe/
https://docs.python.org/3/library/time.html#time.perf_counter
https://docs.python.org/2/library/timeit.html
https://www.programcreek.com/python/example/84234/time.process_time
https://stackoverflow.com/questions/19951816/python-changes-to-my-copy-variable-affect-the-original-variable
http://www.scholarpedia.org/article/N-body_simulations
https://docs.dask.org/en/latest/dataframe-api.html
https://stackoverflow.com/questions/44602766/unpacking-result-of-delayed-function
https://stackoverflow.com/questions/48728383/dask-delayed-object-of-unspecified-length-not-iterable-error-when-combining-dict
https://examples.dask.org/applications/embarrassingly-parallel.html
https://docs.google.com/presentation/d/1hcgwy6S7QXVCIZHI0_Rb7_9FPHQP8HH6iWmaqCKpdIU/edit#slide=id.g4011a25655_0_15/https://www.sdsc.edu/education_and_training/training/201905_distributed_parallel_computing_with_python.html
https://docs.dask.org/en/latest/delayed-best-practices.html#avoid-calling-delayed-within-delayed-functions #Very helpful
https://docs.dask.org/en/latest/delayed-api.html
https://portal.xsede.org/software#/


Dask Library Reference
https://distributed.dask.org/en/latest/client.html
https://distributed.dask.org/en/latest/quickstart.html
https://docs.dask.org/en/latest/
https://docs.dask.org/en/latest/setup.html
https://distributed.dask.org/en/latest/locality.html



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