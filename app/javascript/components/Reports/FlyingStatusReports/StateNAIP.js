import React, { Fragment } from "react";
import { Divider, Table } from "semantic-ui-react";
import "semantic-ui-css/semantic.min.css";
import MessageBox from "../../Shared/MessageBox";

export default function StateNAIP({ results }) {
  console.log("StateNAIP", {
    results,
  });

  if (results.length === 0) {
    return (
      <MessageBox
        title={"No Records Found"}
        message={"Query returned no records"}
      />
    );
  }

  const renderRecords = () => {
    let list = [];

    var grand_total = {
      total_sites: 0,
      total_flown: 0,
      sq_miles: 0,
      asi_accepted: 0,
      asi_rejected: 0,
      usda_accepted: 0,
      usda_rejected: 0,
    };

    for (let i = 0; i < results.length; i++) {
      let record = results[i];

      list.push(
        <Table.Row key={i}>
          <Table.Cell>{record.state_name}</Table.Cell>
          <Table.Cell>{record.total_sites}</Table.Cell>
          <Table.Cell>{record.total_flown}</Table.Cell>
          <Table.Cell>{record.sq_miles}</Table.Cell>
          <Table.Cell>{record.asi_accepted}</Table.Cell>
          <Table.Cell>{record.asi_rejected}</Table.Cell>
          <Table.Cell>{record.usda_accepted}</Table.Cell>
          <Table.Cell>{record.usda_rejected}</Table.Cell>
          <Table.Cell>{record.asi_accepted_percentage}%</Table.Cell>
          <Table.Cell>{record.asi_rejected_percentage}%</Table.Cell>
          <Table.Cell>{record.usda_accepted_percentage}%</Table.Cell>
          <Table.Cell>{record.usda_rejected_percentage}%</Table.Cell>
        </Table.Row>
      );

      // Update grand totals
      grand_total.total_sites += record.total_sites;
      grand_total.total_flown += record.total_flown;
      grand_total.sq_miles += record.sq_miles;
      grand_total.asi_accepted += record.asi_accepted;
      grand_total.asi_rejected += record.asi_rejected;
      grand_total.usda_accepted += record.usda_accepted;
      grand_total.usda_rejected += record.usda_rejected;

      if (i == results.length - 1) {
        list.push(
          <Table.Row
            key={`grand_total`}
            style={{ background: "#efefef", fontWeight: "bold" }}
          >
            <Table.Cell>Grand Total</Table.Cell>
            <Table.Cell>{grand_total.total_sites}</Table.Cell>
            <Table.Cell>{grand_total.total_flown}</Table.Cell>
            <Table.Cell>{grand_total.sq_miles.toFixed(2)}</Table.Cell>
            <Table.Cell>{grand_total.asi_accepted}</Table.Cell>
            <Table.Cell>{grand_total.asi_rejected}</Table.Cell>
            <Table.Cell>{grand_total.usda_accepted}</Table.Cell>
            <Table.Cell>{grand_total.usda_rejected}</Table.Cell>
            <Table.Cell>
              {(
                (grand_total.asi_accepted / grand_total.total_flown) *
                100
              ).toFixed(2)}
              %
            </Table.Cell>
            <Table.Cell>
              {(
                (grand_total.asi_rejected / grand_total.total_flown) *
                100
              ).toFixed(2)}
              %
            </Table.Cell>
            <Table.Cell>
              {(
                (grand_total.usda_accepted / grand_total.total_flown) *
                100
              ).toFixed(2)}
              %
            </Table.Cell>
            <Table.Cell>
              {(
                (grand_total.usda_rejected / grand_total.total_flown) *
                100
              ).toFixed(2)}
              %
            </Table.Cell>
          </Table.Row>
        );
      }
    }

    return list;
  };

  return (
    <Fragment>
      <Divider />
      <Table celled textAlign="center">
        <Table.Header>
          <Table.Row>
            <Table.HeaderCell>State Name</Table.HeaderCell>
            <Table.HeaderCell>Total Sites</Table.HeaderCell>
            <Table.HeaderCell>Total Flown</Table.HeaderCell>
            <Table.HeaderCell>Total SQ Miles Flown</Table.HeaderCell>
            <Table.HeaderCell>ASI Accepted</Table.HeaderCell>
            <Table.HeaderCell>ASI Rejected</Table.HeaderCell>
            <Table.HeaderCell>USDA Accepted</Table.HeaderCell>
            <Table.HeaderCell>USDA Rejected</Table.HeaderCell>
            <Table.HeaderCell>% ASI Accepted</Table.HeaderCell>
            <Table.HeaderCell>% ASI Rejected</Table.HeaderCell>
            <Table.HeaderCell>% USDA Accepted</Table.HeaderCell>
            <Table.HeaderCell>% USDA Rejected</Table.HeaderCell>
          </Table.Row>
        </Table.Header>

        <Table.Body>{renderRecords()}</Table.Body>
      </Table>
    </Fragment>
  );
}
