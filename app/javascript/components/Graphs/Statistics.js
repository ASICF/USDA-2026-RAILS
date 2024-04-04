import React, { useState, useEffect } from "react";
import {
  Card,
  Grid,
  Statistic,
  StatisticValue,
  StatisticLabel,
  StatisticGroup,
  Transition,
} from "semantic-ui-react";
function Statistics({
  project,
  states,
  counties,
  tile_count,
  tile_flown,
  flown,
  tile_shipped,
  shipped,
  acres_count,
  acres_flown,
  acres_percentage,
}) {
  const [visible, setVisible] = useState(false);

  // Transitions only work if they are flipped from false to true
  useEffect(() => {
    setVisible(true);
  }, []);

  return (
    <Transition visible={visible} animation="fade down" duration={1000}>
      <Card fluid>
        <Card.Content className="sl">
          <Card.Header>{project} Statistics</Card.Header>
        </Card.Content>
        <Card.Content className="sl">
          <StatisticGroup widths="seven" size={"mini"}>
            <Statistic>
              <StatisticValue>{states}</StatisticValue>
              <StatisticLabel className="sl-color">
                Active States
              </StatisticLabel>
            </Statistic>

            <Statistic>
              <StatisticValue>{counties}</StatisticValue>
              <StatisticLabel>Counties</StatisticLabel>
            </Statistic>

            <Statistic>
              <StatisticValue>{tile_count}</StatisticValue>
              <StatisticLabel>Total Tiles</StatisticLabel>
            </Statistic>

            <Statistic>
              <StatisticValue>{tile_flown}</StatisticValue>
              <StatisticLabel>Tiles Flown</StatisticLabel>
            </Statistic>

            <Statistic>
              <StatisticValue>{flown}%</StatisticValue>
              <StatisticLabel>Tiles Flown</StatisticLabel>
            </Statistic>

            <Statistic>
              <StatisticValue>{tile_shipped}</StatisticValue>
              <StatisticLabel>Tiles Shipped</StatisticLabel>
            </Statistic>

            <Statistic>
              <StatisticValue>{shipped}%</StatisticValue>
              <StatisticLabel>Shipped</StatisticLabel>
            </Statistic>
          </StatisticGroup>
          <StatisticGroup
            widths="three"
            size={"mini"}
            style={{ paddingTop: "2em" }}
          >
            <Statistic>
              <StatisticValue>{acres_count}</StatisticValue>
              <StatisticLabel>Total Acres</StatisticLabel>
            </Statistic>

            <Statistic>
              <StatisticValue>{acres_flown}</StatisticValue>
              <StatisticLabel>Acres Flown</StatisticLabel>
            </Statistic>

            <Statistic>
              <StatisticValue>{acres_percentage}%</StatisticValue>
              <StatisticLabel>Acres Flown</StatisticLabel>
            </Statistic>
          </StatisticGroup>
        </Card.Content>
      </Card>
    </Transition>
  );
}

export default Statistics;
