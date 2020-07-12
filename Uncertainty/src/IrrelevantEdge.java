import java.util.ArrayList;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Set;

import aima.core.probability.RandomVariable;
import aima.core.probability.bayes.BayesianNetwork;
import aima.core.probability.bayes.FiniteNode;
import aima.core.probability.bayes.Node;
import aima.core.probability.bayes.impl.BayesNet;
import aima.core.probability.bayes.impl.CPT;
import aima.core.probability.bayes.impl.FullCPTNode;
import aima.core.probability.example.BayesNetExampleFactory;
import aima.core.probability.proposition.AssignmentProposition;

public class IrrelevantEdge {

    public static BayesianNetwork irrelevantEdgeGraph(BayesianNetwork bn, AssignmentProposition[] ap) {

        List<Node> newNodes = new ArrayList<>();

        List<RandomVariable> vars = bn.getVariablesInTopologicalOrder();

        for (RandomVariable r : vars) {
            Node nodeSource = bn.getNode(r);

            CPT cpt;
            double[] values;

            if (!eviContain(ap, nodeSource.getParents()).isEmpty()) {
                cpt = (CPT) nodeSource.getCPD();
                values = cpt.getConditioningCase(ap).getValues();
                Set<Node> parent = copyParents(nodeSource.getParents(), newNodes);

                parent.removeAll(eviContain(ap, nodeSource.getParents()));
                FiniteNode[] parents = parent.toArray(new FiniteNode[parent.size()]);
                FiniteNode[] newParents = getnewParent(parents, newNodes);
                FiniteNode newNode = new FullCPTNode(r, values, newParents);
                newNodes.add(newNode);

            } else {

                cpt = (CPT) nodeSource.getCPD();
                values = cpt.getFactorFor().getValues();
                FiniteNode[] parent = nodeSource.getParents().toArray(new FiniteNode[nodeSource.getParents().size()]);
                FiniteNode[] newParents = getnewParent(parent, newNodes);
                FiniteNode newNode = new FullCPTNode(r, values, newParents);
                newNodes.add(newNode);

            }
        }

        ArrayList<FiniteNode> rootsTemp = new ArrayList<>();

        for (Node n : newNodes) {
            if (n.getParents().isEmpty()) {
                rootsTemp.add((FiniteNode) n);
            }
        }

        FiniteNode[] roots = rootsTemp.toArray(new FiniteNode[rootsTemp.size()]);
        BayesianNetwork newBn = new BayesNet(roots);

        return newBn;
    }

    public static Set<Node> copyParents(Set<Node> parent, List<Node> newNodes) {
        Set<Node> copyParents = new HashSet<>();

        Iterator<Node> parIterator = parent.iterator();
        while (parIterator.hasNext()) {
            Node node = parIterator.next();
            for (Node newNode : newNodes) {
                if (newNode.equals(node)) {
                    copyParents.add(node);
                }
            }

        }

        return copyParents;
    }

    public static FiniteNode[] getnewParent(FiniteNode[] parents, List<Node> newNodes) {

        List<FiniteNode> newParentsTemp = new ArrayList<>();

        for (int i = 0; i < parents.length; i++) {
            for (int j = i; j < newNodes.size(); j++) {
                if (parents[i].getRandomVariable().equals(newNodes.get(j).getRandomVariable())) {
                    newParentsTemp.add((FiniteNode) newNodes.get(j));
                }
            }
        }

        FiniteNode[] newParents = newParentsTemp.toArray(new FiniteNode[newParentsTemp.size()]);

        return newParents;
    }

    public static Set<Node> eviContain(AssignmentProposition[] ap, Set<Node> nodes) {

        Set<Node> nodi = new HashSet<>();

        for (int i = 0; i < ap.length; i++) {
            Iterator<Node> it = nodes.iterator();
            while (it.hasNext()) {
                Node parent = it.next();
                if (parent.getRandomVariable().equals(ap[i].getTermVariable())) {
                    nodi.add(parent);
                }
            }
        }

        return nodi;
    }

    public static void main(String[] args) {
        BayesianNetwork bn = BayesNetExampleFactory.constructBurglaryAlarmNetwork();

        System.out.println(bn.getVariablesInTopologicalOrder());

        AssignmentProposition[] ap = new AssignmentProposition[1];

        ap[0] = new AssignmentProposition(bn.getVariablesInTopologicalOrder().get(2), true);

        BayesianNetwork ok = irrelevantEdgeGraph(bn, ap);
    }
}
