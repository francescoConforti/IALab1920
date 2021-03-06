/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package utils;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 *
 * @author confo
 * @param <T> type of the node
 */
// Java program to implement undirected Graph 
// with the help of Generics 
  

  
public class Graph<T> { 
  
    // We use Hashmap to store the edges in the graph 
    private final Map<T, Set<T> > map = new HashMap<>(); 
  
    // This function adds a new vertex to the graph 
    public void addVertex(T s) 
    { 
        map.put(s, new HashSet<>()); 
    }
  
    // This function adds the edge 
    // between source to destination 
    public void addEdge(T s, T d, boolean bidirectional) 
    { 
  
        if (!map.containsKey(s)){ 
            addVertex(s); 
        }
        if (!map.containsKey(d)){
            addVertex(d);
        }
        map.get(s).add(d);
        if(bidirectional){
            map.get(d).add(s);
        }
    }
    
    public Set<T> vertexSet(){
        return map.keySet();
    }
  
    // This function gives whether 
    // a vertex is present or not. 
    public boolean hasVertex(T s) 
    { 
        return map.containsKey(s);
    } 
  
    // This function gives whether an edge is present or not. 
    public boolean hasEdge(T s, T d) 
    { 
        return map.get(s).contains(d);
    }
    
    public void removeVertex(T v){
        map.remove(v);
        for(Map.Entry<T, Set<T>> entry : map.entrySet()){
            Set<T> neighbors = entry.getValue();
            neighbors.remove(v);
        }
    }
    
    public void removeEdge(T s, T d){
        map.get(d).remove(s);
        map.get(s).remove(d);
    }
    
    public Set<T> neighbors(T v){
        return map.get(v);
    }
    
    public Set<T> neighborsDestructive(T v){
        return map.remove(v);
    }
    
    public int get_nr_rootNode() {
    	int count = 0;
    	Set<T> nodi = vertexSet();
    	for (T n : nodi) {
            if(map.get(n).isEmpty()) {
                count++;
            }
    	}	
    	return count;
    }
    
    public Set<T> get_children(T v) {
    	return map.get(v);	
    }
    
    // restituisce i genitori di un nodo
    public List<T> get_parent(T v) {
    	List<T> parent = new ArrayList<>();
    	Set<T> keys = map.keySet();
    	Iterator iterator = keys.iterator();
    	while(iterator.hasNext()) {
            T key = (T) iterator.next();
            if(map.get(key).contains(v)) {
                parent.add(key);
            }
    	}
    	return parent;	
    }
    
    public Graph<T> copy(){
        Graph copy = new Graph<>();
        for(T vertex : map.keySet()){
            copy.addVertex(vertex);
            for(T neighbor : this.neighbors(vertex)){
                copy.addEdge(vertex, neighbor, true);
            }
        }
        return copy;
    }
  
    // Prints the adjancency list of each vertex. 
    @Override
    public String toString() 
    { 
        StringBuilder builder = new StringBuilder(); 
  
        for (T v : map.keySet()) { 
            builder.append(v.toString() + ": "); 
            for (T w : map.get(v)) { 
                builder.append(w.toString() + " "); 
            } 
            builder.append("\n"); 
        } 
  
        return (builder.toString()); 
    } 
} 