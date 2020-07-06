
import aima.core.probability.Factor;
import aima.core.probability.RandomVariable;
import aima.core.probability.bayes.BayesianNetwork;
import aima.core.probability.bayes.FiniteNode;
import aima.core.probability.bayes.Node;
import aima.core.probability.bayes.impl.BayesNet;
import aima.core.probability.bayes.impl.FullCPTNode;
import aima.core.probability.domain.BooleanDomain;
import aima.core.probability.example.BayesNetExampleFactory;
import aima.core.probability.proposition.AssignmentProposition;
import aima.core.probability.util.RandVar;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Set;
import utils.Graph;

/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
/**
 *
 * @author confo
 */
public class Pruning {

    public final String MINDEGREEORDER = "minDegreeOrder";
    public final String MINFILLORDER = "minFillOrder";
    
    public BayesianNetwork theorem1(BayesianNetwork bn,
            RandomVariable[] queryVars,
            AssignmentProposition[] assignmentPropositions) {
        List<RandomVariable> topologicalOrder = bn.getVariablesInTopologicalOrder();
        List<RandomVariable> relevantRVs = theorem1Help(bn, queryVars, assignmentPropositions);
        Collections.reverse(relevantRVs);
        return newNetFromRandomVars(bn, topologicalOrder, relevantRVs, assignmentPropositions);
    }
    
    /*
        creates a new Bayesian network where the relevant variables are newNetVars and the others are deleted.
        oldNetVars must be in topological order
    */
    private BayesNet newNetFromRandomVars(BayesianNetwork oldNet,
            List<RandomVariable> oldNetVars,
            List<RandomVariable> newNetVars,
            AssignmentProposition[] aps){
        List<FiniteNode> newNodes = new ArrayList<>();
        for (RandomVariable var : oldNetVars) {
            if (newNetVars.contains(var)) {
                Node node = oldNet.getNode(var);
                FiniteNode fn = (FiniteNode) node;
                Set<Node> parents = node.getParents();
                Set<Node> newParents = new HashSet<>();
                for (Node p : parents) {  // I need to set as parents the new nodes, not the ones of the old bn
                    for (Node np : newNodes) {
                        if (p.equals(np)) {
                            newParents.add(np);
                        }
                    }
                }
                double[] cptVal = getNewCPT(fn, newParents, aps);
                newNodes.add(new FullCPTNode(var, cptVal, newParents.toArray(new Node[parents.size()])));
            }
        }
        List<Node> roots = new ArrayList<>();
        for (Node node : newNodes) {
            if (node.isRoot()) {
                roots.add(node);
            }
        }

        return new BayesNet(roots.toArray(new Node[roots.size()]));
    }

    /*
    iterate through the random variables in inverse topological order;
    delete the variables in the last level if they are not query or evidence;
    at each subsequent level keep the new query and evidence variables found and
    all of those which still have at least one child (ancestors of relevant variables)
    @returns a list of the relevant random variables in inverse topological order
     */
    private List<RandomVariable> theorem1Help(BayesianNetwork bn,
            RandomVariable[] queryVars,
            AssignmentProposition[] assignmentPropositions) {
        List<RandomVariable> topologicalOrder = bn.getVariablesInTopologicalOrder();
        List<RandomVariable> varList = new ArrayList<>(topologicalOrder);
        Collections.reverse(varList);
        RandomVariable[] evidenceVars = assignmentPropositionToRandomVariable(assignmentPropositions);
        for (Iterator<RandomVariable> iterator = varList.iterator(); iterator.hasNext();) {
            RandomVariable var = iterator.next();
            boolean keep = false;
            for (int i = 0; i < queryVars.length; i++) {
                if (var.getName().equals(queryVars[i].getName())) {
                    keep = true;
                }
            }
            for (int i = 0; i < evidenceVars.length; i++) {
                if (var.getName().equals(evidenceVars[i].getName())) {
                    keep = true;
                }
            }
            for (Node child : bn.getNode(var).getChildren()) {
                if (varList.contains(child.getRandomVariable())) {
                    keep = true;
                }
            }
            if (!keep) {
                iterator.remove();
            }
        }
        return varList;
    }
    
    public RandomVariable[] assignmentPropositionToRandomVariable(AssignmentProposition[] aps){
        RandomVariable[] rvs = new RandomVariable[aps.length];
        for(int i = 0; i < aps.length; ++i){
            rvs[i] = aps[i].getTermVariable();
        }
        return rvs;
    }
    
    public BayesianNetwork theorem2(BayesianNetwork bn,
            RandomVariable[] queryVars,
            AssignmentProposition[] assignmentPropositions) {
        List<RandomVariable> topologicalOrder = bn.getVariablesInTopologicalOrder();
        List<RandomVariable> topologicalOrderCopy = new ArrayList<>(topologicalOrder);
        Graph moralGraph = moralGraph(bn);
        RandomVariable[] evidenceVars = assignmentPropositionToRandomVariable(assignmentPropositions);
        topologicalOrderCopy.removeAll(Arrays.asList(queryVars));
        topologicalOrderCopy.removeAll(Arrays.asList(evidenceVars));
        List<RandomVariable> relevantVars = new ArrayList<>();
        relevantVars.addAll(Arrays.asList(queryVars));
        relevantVars.addAll(Arrays.asList(evidenceVars));
        for(RandomVariable rvar : topologicalOrderCopy){
            Node end = bn.getNode(rvar);
            for(int i = 0; i < queryVars.length; ++i){
                Node start = bn.getNode(queryVars[i]);
                if(!relevantVars.contains(rvar) && !isMSeparated(moralGraph, start, end, evidenceVars)){
                    relevantVars.add(rvar);
                }
            }
        }
        return newNetFromRandomVars(bn, topologicalOrder, relevantVars, assignmentPropositions);
    }

    public Graph moralGraph(BayesianNetwork bn) {
        Graph<Node> graph = new Graph<>();

        List<RandomVariable> variables = bn.getVariablesInTopologicalOrder();

        for (RandomVariable r : variables) {
            Node node = bn.getNode(r);
            graph.addVertex(node);
        }

        for (RandomVariable r : variables) {
            Node node = bn.getNode(r);
            Node[] parents = node.getParents().toArray(new Node[node.getParents().size()]);

            for (int i = 0; i < parents.length; i++) {
                graph.addEdge(parents[i], node, true);
                for (int j = i + 1; j < parents.length; j++) {
                    graph.addEdge(parents[i], parents[j], true);
                }
            }
        }
        return graph;
    }

    /*
    This method and its helper are not efficient but are easy to write and read
    */
    private boolean isMSeparated(Graph<Node> graph, Node start, Node end, RandomVariable[] eviVar) {
        return isMSeparatedHelp(graph.copy(), start, end, eviVar);
    }

    private boolean isMSeparatedHelp(Graph<Node> graph, Node start, Node end, RandomVariable[] eviVar) {
        boolean ret = true;
        for (RandomVariable r : eviVar) {
            String nameEvi = r.getName();
            String nameVar = start.getRandomVariable().getName();
            if (nameVar.contentEquals(nameEvi)) {
                return true;
            }
        }

        if (start.equals(end)) {
            return false;
        } else {
            List<Node> neighbors = graph.neighborsDestructive(start);
            if(neighbors != null){
                for (Node n : neighbors) {
                    ret = ret && isMSeparatedHelp(graph, n, end, eviVar);
                }
            }
        }
        return ret;
    }
    
    public static double[] getNewCPT(FiniteNode node, Set<Node> parentsNewNode, AssignmentProposition[] ap){
        double[] newCPT = null;
        List<RandomVariable> toSumOut = new ArrayList<>();
        for(Node parent : node.getParents()){
            if(!parentsNewNode.contains(parent)){
                toSumOut.add(parent.getRandomVariable());
            }
        }
        Factor f = node.getCPT().getFactorFor();
        // normalize sums
        newCPT = f.sumOut(toSumOut.toArray(new RandomVariable[toSumOut.size()])).getValues();
        for(int i = 0; i < newCPT.length; i = i+2){
            double num1 = newCPT[i] / (newCPT[i] + newCPT[i+1]);
            double num2 = newCPT[i+1] / (newCPT[i] + newCPT[i+1]);
            newCPT[i] = num1;
            newCPT[i+1] = num2;
        }
        return newCPT;
    }
    
    /*
        implements minDegreeOrder and minFillOrder
        Which order is chosen through the String parameter (use the constants provided in this class)
    */
    public List<RandomVariable> order(BayesianNetwork bn, String order){
        if(!order.equals(MINDEGREEORDER) && !order.equals(MINFILLORDER)){
            System.out.println("order: wrong String parameter");
            return null;
        }
        List<RandomVariable> minDegreeOrder = new ArrayList<>();
        Graph<Node> interactionGraph = moralGraph(bn);
        Set<Node> nodeSet = interactionGraph.vertexSet();
        while(!nodeSet.isEmpty()){
            Node next = new FullCPTNode(new RandVar("ERROR", new BooleanDomain()), new double[] {0.5,0.5}); // make compiler happy;
            if(order.equals(MINDEGREEORDER)){
                next = minDegreeOrder(interactionGraph);
            } else if(order.equals(MINFILLORDER)){
                next = minFillOrder(interactionGraph);
            }
            minDegreeOrder.add(next.getRandomVariable());
            List<Node> neighbors = interactionGraph.neighborsDestructive(next);
            Node[] neighborsArr = neighbors.toArray(new Node[neighbors.size()]);
            for(int i = 0; i < neighborsArr.length; ++i){
                for(int j = i+1; j < neighborsArr.length; ++j){
                    if(!interactionGraph.hasEdge(neighborsArr[i], neighborsArr[j])){
                        interactionGraph.addEdge(neighborsArr[i], neighborsArr[j], true);
                    }
                }
            }
            interactionGraph.removeVertex(next);
            nodeSet = interactionGraph.vertexSet();
        }
        return minDegreeOrder;
    }
    
    /*
        return the node with the smallest number of neighbors
    */
    private Node minDegreeOrder(Graph<Node> interactionGraph){
        Set<Node> nodeSet = interactionGraph.vertexSet();
        int min = nodeSet.size();
        Node next = null;
        for(Node n : nodeSet){
            int degree = interactionGraph.neighbors(n).size();
            if(degree < min){
                min = degree;
                next = n;
            }
        }
        return next;
    }
    
    /*
        return the node whose elimination will produce the least number of new
        edges in the interaction graph
    */
    private Node minFillOrder(Graph<Node> interactionGraph){
        Set<Node> nodeSet = interactionGraph.vertexSet();
        int min = (int) Math.pow(nodeSet.size(), 2);
        Node next = null;
        for(Node n : nodeSet){
            int curr = 0;
            Node[] neighbors = interactionGraph.neighbors(n).toArray(new Node[0]);
            for(int i = 0; i < neighbors.length; ++i){
                for(int j = i+1; j < neighbors.length; ++j){
                    if(!interactionGraph.hasEdge(neighbors[i], neighbors[j])){
                        ++curr;
                    }
                }
            }
            if(curr < min){
                min = curr;
                next = n;
            }
        }
        return next;
    }

    public static void main(String[] args) {
        Pruning p = new Pruning();
        BayesianNetwork bn = BayesNetExampleFactory.constructBurglaryAlarmNetwork();
        //BayesianNetwork bn = BayesNetExampleFactory.constructCloudySprinklerRainWetGrassNetwork();
        List<RandomVariable> varList = bn.getVariablesInTopologicalOrder();
        RandomVariable[] queryVars = new RandomVariable[1];
        AssignmentProposition[] ap = new AssignmentProposition[1];
        for (RandomVariable rv : varList) {
            if (rv.getName().equals("Burglary")) {
                queryVars[0] = rv;
                FiniteNode fn = (FiniteNode) bn.getNode(rv);
            }
            if (rv.getName().equals("Alarm")) {
                ap[0] = new AssignmentProposition(rv, true);
            }
        }
        //BayesianNetwork newBN = p.theorem2(bn, queryVars, ap);
        //System.out.println(newBN.getVariablesInTopologicalOrder());
        System.out.println("topologicalOrder: " + bn.getVariablesInTopologicalOrder());
        System.out.println("minDegree: " + p.order(bn, p.MINDEGREEORDER));
        System.out.println("minFill: " + p.order(bn, p.MINFILLORDER));
    }
}
